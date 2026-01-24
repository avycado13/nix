{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [ grc ];
  programs = {
    nix-index-database.comma.enable = true;
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        gcloud = {
          detect_env_vars = [ "GOOGLE_CLOUD" ];
        };
        aws = {
          disabled = true;
        };
      };
    };

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
      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-syntax-highlighting"; }
          { name = "zsh-users/zsh-completions"; }
          { name = "zsh-users/zsh-history-substring-search"; }
          { name = "unixorn/warhol.plugin.zsh"; }
          { name = "davidosomething/git-my"; }
          { name = "MichaelAquilina/zsh-you-should-use"; }
          { name = "zsh-users/zsh-syntax-highlighting"; }
        ];
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "direnv"
          "kitty"
          "git"
          "aliases"
          "alias-finder"
          # "git-extra-commands"
          "python"
          "sudo"
          "colored-man-pages"
          "uv"
        ];
      };
      shellAliases = {
        manix-fzf = "'manix' | rg '^# ' | sed 's/^# \\(.*\\) (.*/\\1/;s/ (.*//;s/^# //' | fzf --preview=\"manix '{}'\" | xargs manix";
        cat = "bat";
        ls = "eza";
        df = "df -h";
        du = "du -ch";
        ipp = "curl ipinfo.io/ip";
        yh = "yt-dlp --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:a copy -c:v copy {}.mkv && rm {}'";
        yd = "yt-dlp --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:v prores_ks -profile:v 1 -vf fps=25/1 -pix_fmt yuv422p -c:a pcm_s16le {}.mov && rm {}'";
        ya = "yt-dlp --continue --no-check-certificate --format=bestaudio -x --audio-format wav";
        ols = "ls -la --color=never | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\" %0o \",k);print}'";
        fzkill = "kill -9 $(ps aux | fzf | awk '{print $2}')";
        aspm = "sudo lspci -vv | awk '/ASPM/{print $0}' RS= | grep --color -P '(^[a-z0-9:.]+|ASPM )'";
        mkdir = "mkdir -p";
        rm = "rm -iv";
        cp = "cp -iv";
        mv = "mv -iv";
        cfip = ''dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"' '';
        rr = "rm -Rf";
        ghrpc = "gh repo create -c";
        goops = "git commit --amend --no-edit && git push --force-with-lease";
      };

      initContent = ''
        export LEDGER_FILE=~/finance/main.journal

        mkdir -p "$HOME/Library/pnpm"
        export PNPM_HOME="$HOME/Library/pnpm"
        export PATH="$PNPM_HOME:$PATH"
        export ANDROID_HOME="$HOME/Library/Android/sdk"
        export ANDROID_SDK_ROOT="$ANDROID_HOME"
        export PATH="$PATH:$ANDROID_HOME/platform-tools"

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
          export EDITOR=nvim
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
    };
    atuin = {
      enable = false;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://api.atuin.sh";
        search_mode = "fuzzy";
        session_path = config.age.secrets."atuin-session".path;
        key_path = config.age.secrets."atuin-key".path;
      };
    };
  };
  home.sessionPath = [
    "$HOME/finance/bin"
    "$HOME/.local/bin"
  ];
}
