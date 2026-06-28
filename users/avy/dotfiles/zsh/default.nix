{
  pkgs,
  config,
  lib,
  ...
}:
let
  musicDir = "${config.home.homeDirectory}/Music/Library";
  mpdDataDir = "${config.xdg.dataHome}/mpd";
  mpdPlaylistDir = "${mpdDataDir}/playlists";
  mpdConfDarwin = pkgs.writeText "mpd.conf" ''
    music_directory     "${musicDir}"
    playlist_directory  "${mpdPlaylistDir}"
    db_file             "${mpdDataDir}/tag_cache"
    state_file          "${mpdDataDir}/state"
    sticker_file        "${mpdDataDir}/sticker.sql"
    log_file            "${mpdDataDir}/mpd.log"
    bind_to_address     "127.0.0.1"
    port                "6600"

    audio_output {
      type "osx"
      name "CoreAudio"
    }
  '';
in
{
  home.sessionPath = [
    "$HOME/finance/bin"
    "$HOME/.local/bin"
  ];
  home.packages =
    with pkgs;
    [
      grc
      scooter
      dua
      procs
      scc
    ]
    # `services.mpd` is Linux-only in home-manager, so install the package
    # directly on Darwin to keep `mpd` available for ncmpcpp.
    ++ lib.optional pkgs.stdenv.isDarwin pkgs.mpd;

  # home-manager's services.mpd module asserts Linux (it generates a
  # systemd user unit), so only enable it on Linux.
  services.mpd = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    musicDirectory = musicDir;
    network.startWhenNeeded = true;

    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
    '';
  };

  # On Darwin, run mpd via a launchd user agent.
  launchd.agents.mpd = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.mpd}/bin/mpd"
        "--no-daemon"
        "${mpdConfDarwin}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardOutPath = "${mpdDataDir}/mpd.log";
      StandardErrorPath = "${mpdDataDir}/mpd.log";
    };
  };

  home.activation.createMpdDirs = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg mpdDataDir} ${lib.escapeShellArg mpdPlaylistDir} ${lib.escapeShellArg musicDir}
    ''
  );
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
      # Loaded via zsh-defer in initContent instead (only binds a widget, so it
      # doesn't need to block the first prompt).
      enableZshIntegration = false;
      settings = {
        cheats = {
          paths = [
            "~/cheats/"
          ];
        };
      };
    };
    ncmpcpp = {
      enable = true;
      mpdMusicDir = musicDir;
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
        indexes = [
          "nixpkgs"
          "nixos"
          "home-manager"
          "nur"
          "noogle"
          "darwin"
        ];
        experimental.options_file = {
          # sops-nix-home = mkOpts pkgs.stdenv.hostPlatform.system inputs.sops-nix.homeModules.default;
          # sops-nix-darwin = mkOpts pkgs.stdenv.hostPlatform.system inputs.sops-nix.darwinModules.default;
          # sops-nix-nixos = mkOpts pkgs.stdenv.hostPlatform.system inputs.sops-nix.nixosModules.default;
          # catppuccin-home = mkOpts pkgs.stdenv.hostPlatform.system inputs.catppuccin.homeModules.default;
          # catppuccin-nixos = mkOpts pkgs.stdenv.hostPlatform.system inputs.catppuccin.nixosModules.default;
        };
        render_docs_indexes = {
          home-manager = "https://nix-community.github.io/home-manager/options.xhtml";
        };
      };
    };
    yt-dlp = {
      enable = true;
      extraConfig = ''
        --ffmpeg-location ${lib.getExe pkgs.ffmpeg}
      '';
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
          # Deferred loading: lets us push non-essential init off the critical
          # path so the prompt renders immediately. Must load first.
          "romkatv/zsh-defer"
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
          "zsh-users/zsh-completions"
          "unixorn/warhol.plugin.zsh"
          "MichaelAquilina/zsh-you-should-use"
          "Aloxaf/fzf-tab"
          "unixorn/git-extra-commands kind:clone branch:main"
        ];
        useFriendlyNames = true;
      };
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      historySubstringSearch.enable = true;
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
        yam = "yt-dlp --embed-metadata --embed-thumbnail -x --audio-format m4a -o '%(title)s.%(ext)s'";
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
            export PATH="$HOME/.cargo/bin:$PATH"
            export PATH="/Users/avy/.bun/bin:$PATH"
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



              if command -v motd &> /dev/null
              then
                motd
              fi
              bindkey -e

              # Defer non-prompt-critical integrations so the first prompt
              # renders immediately; these finish loading right after it appears.
              # The single-quoted inner string ensures the subprocess only runs
              # when zsh-defer fires (not at startup).
              zsh-defer eval 'eval "$(terminal-wakatime init)"'
              zsh-defer eval 'eval "$(navi widget zsh)"'
              bindkey '^[n' _navi_widget
              bindkey -r '^G' # remove ^G mapping for navi

              mdc() { mkdir -p "$1" && cd "$1"; }

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
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://api.atuin.sh";
        search_mode = "fuzzy";
        session_path = config.sops.secrets.atuin-session.path;
        key_path = config.sops.secrets.atuin-key.path;
      };
    };
  };

}
