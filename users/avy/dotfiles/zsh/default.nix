{
  pkgs,
  config,
  # agenixOptions ? null,
  ...
}:
{
  home.sessionPath = [
    "$HOME/finance/bin"
    "$HOME/.local/bin"
  ];
  home.packages = with pkgs; [
    grc
    scooter
    dua
    procs
    scc
  ];
  programs = {
    nix-index-database.comma.enable = true;
    starship = {
      enable = true;

      settings = {
        add_newline = false;
        #   format = "$env_var.zmx$all";

        # env_var = {
        #   zmx = {
        #     variable = "ZMX_SESSION";
        #     format = "[$env_value] ";
        #   };
        # };
        gcloud = {
          detect_env_vars = [ "GOOGLE_CLOUD" ];
        };
        aws = {
          disabled = true;
        };
      };
    };
    navi = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        cheats = {
          paths = [
            "~/cheats/"
          ];
        };
      };
    };
    rclone.enable = true;
    bat = {
      enable = true;
    };
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };
    fd.enable = true;
    pandoc.enable = true;

    nix-search-tv = {
      enable = true;
      settings = {
        # experimental.options_file = { } // (if agenixOptions != null then { agenix = "${agenixOptions}"; } else { });
      };
    };
    yt-dlp = {
      enable = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    ripgrep = {
      enable = true;
    };
    zsh = {
      enable = true;
      enableCompletion = false;
      antidote = {
        enable = true;
        plugins = [
          "ohmyzsh/ohmyzsh path:lib"
          "getantidote/use-omz"
          "ohmyzsh/ohmyzsh path:plugins/direnv"
          "ohmyzsh/ohmyzsh path:plugins/kitty"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/aliases"
          "ohmyzsh/ohmyzsh path:plugins/alias-finder"
          "ohmyzsh/ohmyzsh path:plugins/python"
          "ohmyzsh/ohmyzsh path:plugins/sudo"
          "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"
          "ohmyzsh/ohmyzsh path:plugins/uv"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-syntax-highlighting"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-history-substring-search"
          "unixorn/warhol.plugin.zsh"
          "MichaelAquilina/zsh-you-should-use"
          "Aloxaf/fzf-tab"
          "unixorn/git-extra-commands kind:clone branch:main"
        ];
        useFriendlyNames = true;
      };
      shellAliases = {
        fzmanix = "'manix' | rg '^# ' | sed 's/^# \\(.*\\) (.*/\\1/;s/ (.*//;s/^# //' | fzf --preview=\"manix '{}'\" | xargs manix";
        cat = "bat";
        ls = "eza";
        df = "df -h";
        du = "du -ch";
        ipp = "curl ipinfo.io/ip";
        yh = "yt-dlp --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:a copy -c:v copy {}.mkv && rm {}'";
        yd = "yt-dlp --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:v prores_ks -profile:v 1 -vf fps=25/1 -pix_fmt yuv422p -c:a pcm_s16le {}.mov && rm {}'";
        ya = "yt-dlp --continue --no-check-certificate --format=bestaudio -x --audio-format wav";
        ols = "ls -la --color=never | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\" %0o \",k);print}'";
        fzkill = "(date; ps -ef) |
  fzf --bind='ctrl-r:reload(date; ps -ef)' \
      --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
      --preview='echo {}' --preview-window=down,3,wrap \
      --layout=reverse --height=80% | awk '{print $2}' | xargs kill -9";
        aspm = "sudo lspci -vv | awk '/ASPM/{print $0}' RS= | grep --color -P '(^[a-z0-9:.]+|ASPM )'";
        mkdir = "mkdir -p";
        rm = "rm -iv";
        cp = "cp -iv";
        mv = "mv -iv";
        cfip = ''dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"' '';
        rr = "rm -Rf";
        ghrpc = "gh repo create -c";
        goops = "git commit --amend --no-edit && git push --force-with-lease";
        jsenv = "rg -o --no-filename 'process\\.env\\.[A-Z0-9_]+' | sort -u | awk -F. '{print $3\"=\\\"\\\"\"}'";
      };

      initContent = ''
            export LEDGER_FILE=~/finance/main.journal

            mkdir -p "$HOME/Library/pnpm"
            export PNPM_HOME="$HOME/Library/pnpm"
            export PATH="$PNPM_HOME:$PATH"
            export ANDROID_HOME="$HOME/Library/Android/sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$PATH:$ANDROID_HOME/platform-tools"

            fancy-ctrl-z() {
          if [[ -z $BUFFER ]]; then
            BUFFER="fg"
            zle accept-line
          else
            zle push-input
            zle clear-screen
          fi
        }
        zle -N fancy-ctrl-z
        bindkey '^Z' fancy-ctrl-z

            # Cycle back in the suggestions menu using Shift+Tab
            bindkey '^[[Z' reverse-menu-complete

            bindkey '^B' autosuggest-toggle
            # Make Ctrl+W remove one path segment instead of the whole path
            WORDCHARS=''${WORDCHARS/\/}

            # Highlight the selected suggestion
            zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
            zstyle ':completion:*' menu yes=long select

              if [ $(uname) = "Darwin" ]; then
                path=("$HOME/.nix-profile/bin" "/run/wrappers/bin" "/etc/profiles/per-user/$USER/bin" "/nix/var/nix/profiles/default/bin" "/run/current-system/sw/bin" "/opt/homebrew/bin" $path)
                export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
                alias flush-dns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
                alias lsblk="diskutil list"
                ulimit -n 2048
              fi
              export LANG=en_US.UTF-8
              export LC_CTYPE=en_US.UTF-8
              export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES


              bindkey '^[[A' history-substring-search-up
              bindkey '^[[B' history-substring-search-down

              if command -v motd &> /dev/null
              then
                motd
              fi
              bindkey -e
              eval "$(terminal-wakatime init)"


      '';
    };
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      colors = "auto";
      icons = "auto";
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = {
        # fg = "#D8DEE9";
        # bg = "#2E3440";
        # hl = "#A3BE8C";
        # "fg+" = "#D8DEE9";
        # "bg+" = "#434C5E";
        # "hl+" = "#A3BE8C";
        # pointer = "#BF616A";
        # info = "#4C566A";
        # spinner = "#4C566A";
        # header = "#4C566A";
        # prompt = "#81A1C1";
        # marker = "#EBCB8B";
      };
    };
    lazydocker = {
      enable = true;
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
    };
    atuin = {
      enable = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://api.atuin.sh";
        search_mode = "fuzzy";
        session_path = config.age.secrets.atuin-session.path;
        key_path = config.age.secrets.atuin-key.path;
      };
    };
  };

}
