{
  pkgs,
  config,
  lib,
  ...
}:

{
  options.dots.shell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the shell dotfiles module.";
    };
  };

  config = lib.mkIf config.dots.shell.enable {

    home.sessionPath = [
      "$HOME/finance/bin"
      "$HOME/.local/bin"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      "$HOME/.cargo/bin"
      "$HOME/.bun/bin"
      "$HOME/.nix-profile/bin"
      "/run/wrappers/bin"
      "/etc/profiles/per-user/$USER/bin"
      "/nix/var/nix/profiles/default/bin"
      "/run/current-system/sw/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/opt/local/bin"
      "/opt/local/sbin"
      "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
      "$HOME/Library/pnpm"
      "$HOME/Library/Android/sdk/platform-tools"
    ];

    home.sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES";
      # Use Apple's toolchain for native builds. nix's cc/clang don't wire in
      # the macOS SDK, so cgo/cargo/cmake links fail with "library not found"
      # (e.g. -lresolv). Apple's cc handles SDK, frameworks, and code signing
      # natively. Respected by cgo ($CC), cargo, cmake, etc.
      CC = "/usr/bin/cc";
      CXX = "/usr/bin/c++";
      DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
    };

    home.activation.mkPnpmHome = lib.mkIf pkgs.stdenv.isDarwin (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${config.home.homeDirectory}/Library/pnpm"
      ''
    );

    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;

        completionInit = ''
          () {
            emulate -L zsh
            [[ -o interactive ]] || return
            autoload -Uz compinit complist
            # Use fpath directory count as cache key (sub-ms vs 89ms for full file glob).
            local zcd="''${ZDOTDIR:-$HOME}/.zcompdump-''${ZSH_VERSION}-''${#fpath}"
            local zcdc=$zcd.zwc
            local zcda=$zcd.last
            if [[ -e $zcda && -n $zcda(#qN.mh+24) ]]; then
              # Stale: rebuild in background, use cached dump this session.
              { compinit -u -d $zcd; : > $zcda; rm -f $zcdc && zcompile $zcd } &!
              compinit -C -d $zcd
            elif [[ -f $zcd ]]; then
              compinit -C -d $zcd
            else
              # First run or missing dump: full init
              compinit -u -d $zcd
              : > $zcda
              [[ ! -f $zcdc || $zcd -nt $zcdc ]] && rm -f $zcdc && zcompile $zcd &!
            fi
          }
        '';
        antidote = {
          enable = true;
          useFriendlyNames = true;

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
            # "MichaelAquilina/zsh-you-should-use"
            # "Aloxaf/fzf-tab"
            "unixorn/git-extra-commands kind:clone branch:main"
          ];
        };

        plugins = [
          {
            name = pkgs.zsh-fzf-tab.pname;
            src = pkgs.zsh-fzf-tab.src;
            file = "fzf-tab.plugin.zsh";
          }
          {
            name = pkgs.zsh-you-should-use.pname;
            src = pkgs.zsh-you-should-use.src;
          }
          {
            name = pkgs.fzf-zsh-plugin.pname;
            src = pkgs.fzf-zsh-plugin.src;
            file = "fzf-zsh-plugin.zsh";
          }
        ];

        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        historySubstringSearch.enable = true;

        shellAliases = {
          ash = "${lib.getExe pkgs.autossh} -M 0 -q";
          aspm = "sudo lspci -vv | awk '/ASPM/{print $0}' RS= | grep --color -P '(^[a-z0-9:.]+|ASPM )'";
          b = "${lib.getExe pkgs.buku} --suggest";
          cat = "${lib.getExe pkgs.bat}";
          cfip = ''dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"' '';
          cp = "cp -iv";
          df = "df -h";
          du = "du -ch";

          fzkill = ''
            (date; ps -ef) |
              ${lib.getExe pkgs.fzf} --bind='ctrl-r:reload(date; ps -ef)' \
                --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
                --preview='echo {}' --preview-window=down,3,wrap \
                --layout=reverse --height=80% |
              awk '{print $2}' | xargs kill -9
          '';

          fzmanix = "'${lib.getExe pkgs.manix}' | rg '^# ' | sed 's/^# \\(.*\\) (.*/\\1/;s/ (.*//;s/^# //' | fzf --preview=\"${lib.getExe pkgs.manix} '{}'\" | xargs manix";
          ghrpc = "${lib.getExe pkgs.gh} repo create -c";
          goops = "${lib.getExe pkgs.git} commit --amend --no-edit && ${lib.getExe pkgs.git} push --force-with-lease";
          ipp = "${lib.getExe pkgs.curl} ipinfo.io/ip";
          jsenv = "${lib.getExe pkgs.ripgrep} -o --no-filename 'process\\.env\\.[A-Z0-9_]+' | sort -u | awk -F. '{print $3\"=\\\"\\\"\"}'";
          ls = "${lib.getExe pkgs.eza}";
          mkdir = "mkdir -p";
          mv = "mv -iv";
          ols = "ls -la --color=never | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\" %0o \",k);print}'";
          rm = "rm -iv";
          rr = "rm -Rf";
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          flush-dns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
          lsblk = "diskutil list";
        };

        initContent = ''
          ${lib.optionalString pkgs.stdenv.isDarwin ''
            builtin ulimit -n 2048
          ''}

          if command -v motd &> /dev/null; then
            motd
          fi

          # --- Keybindings & widgets ---
          bindkey -e

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

          # --- Deferred integrations (pushed off the critical path so the
          # first prompt renders immediately; these finish loading right
          # after it appears) ---
          zsh-defer eval 'eval "$(terminal-wakatime init)"'
          zsh-defer eval 'eval "$(navi widget zsh)"'
          bindkey '^[n' _navi_widget
          bindkey -r '^G'

          # --- Functions ---
          mdc() {
            mkdir -p "$1" && cd "$1"
          }
        '';
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
      bat.enable = true;
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
      eza = {
        enable = true;
        enableZshIntegration = true;
        git = true;
        colors = "auto";
        icons = "auto";
      };
      fd.enable = true;
      fzf = {
        enable = true;
        enableZshIntegration = true;

        historyWidget.command = "";
      };
      navi = {
        enable = true;

        # Loaded via zsh-defer in initContent instead (only binds a widget, so it
        # doesn't need to block the first prompt).
        enableZshIntegration = false;

        settings.cheats.paths = [
          "~/cheats/"
        ];
      };
      nix-index = {
        enable = true;
        enableZshIntegration = true;
      };
      nix-index-database.comma.enable = true;
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

          render_docs_indexes.home-manager = "https://nix-community.github.io/home-manager/options.xhtml";
        };
      };
      pandoc.enable = true;

      rclone.enable = true;

      ripgrep.enable = true;

      starship = {
        enable = true;

        settings = {
          add_newline = false;

          # format = ''
          #   ''${env_var.ZMX_SESSION}\
          #   $directory\
          #   $git_branch\
          #   $git_status\
          #   $character
          # '';

          # env_var.ZMX_SESSION = {
          #   symbol = " ";
          #   format = "[$symbol$env_value]($style) ";
          #   description = "zmx session name";
          #   style = "bold magenta";
          # };

          aws.disabled = true;

          gcloud.detect_env_vars = [
            "GOOGLE_CLOUD"
          ];
        };
      };
      yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "yy";
      };

      yt-dlp = {
        enable = true;

        extraConfig = ''
          --ffmpeg-location ${lib.getExe pkgs.ffmpeg}
        '';
      };

      zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [ "--cmd cd" ];
      };
    };
  };
}
