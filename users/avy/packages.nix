{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components;
    [
      gke-gcloud-auth-plugin
    ]
  );

  # zmx = import ../../packages/zmx.nix {
  #   inherit pkgs;
  #   inherit (pkgs)
  #     lib
  #     stdenv
  #     fetchurl
  #     autoPatchelfHook
  #     ;
  # };

  ai = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    amp
    copilot-cli
    crush
    # pi
    opencode
    antigravity-cli
    grok
    codex
    claude-code
  ];
  aiMap = builtins.listToAttrs (
    map (
      pkg:
      let
        raw = pkg.pname or pkg.name;
        display = lib.removeSuffix "-cli" raw;
      in
      {
        name = display;
        value = {
          bin = "${pkg}/bin/${raw}";
        };
      }
    ) ai
  );

  irc-pkg = pkgs.weechat.override {
    configure =
      { availablePlugins, ... }:
      {
        plugins = with availablePlugins; [
          python
          perl
          ruby
          lua
        ];

        scripts = with pkgs.weechatScripts; [
          autosort
          weechat-grep
          buffer_autoset
          highmon
          weechat-go
          edit
          multiline
          url_hint
          wee-slack
        ];
        # ++ [
        #   (pkgs.linkFarm "weechat-scripts" {
        #     colorize_nicks = "${inputs.weechat-scripts}/python/colorize_nicks.py";
        #     kitty_notifications = "${inputs.weechat-scripts}/python/kitty_notifications.py";
        #     anti_password = "${inputs.weechat-scripts}/python/anti_password.py";
        #   })
        # ];
      };
  };
in
{
  home.packages = ai ++ [
    irc-pkg
    pkgs.zmx
    # pkgs.nur.repos.avycado13.anylinuxfs-gui
    inputs.wakatime-ls.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Basic Utilities
    pkgs.onefetch
    pkgs.fastfetch
    pkgs.git-extras
    pkgs.devenv
    pkgs.caligula
    pkgs.manix
    pkgs.nh
    pkgs.nix-bisect
    pkgs.nix-btm
    pkgs.nix-check-deps
    pkgs.sops
    pkgs.pnpm
    pkgs.magic-wormhole
    gdk
    pkgs.curl
    pkgs.wget
    pkgs.htop
    pkgs.btop
    pkgs.tree
    pkgs.cowsay
    pkgs.file
    pkgs.angrr
    pkgs.jnv
    pkgs.clipboard-jh
    pkgs.nmap
    pkgs.ffuf
    pkgs.serie
    pkgs.nurl
    pkgs.which
    pkgs.gnused
    pkgs.gnutar
    pkgs.gawk
    pkgs.coreutils
    # pkgs.pkgconf
    pkgs.pkg-config
    pkgs.dbus
    pkgs.cmake
    pkgs.wakatime-cli
    pkgs.cmus
    pkgs.restic
    pkgs.gum
    pkgs.jq
    pkgs.ts
    pkgs.hyperfine
    pkgs.duf
    pkgs.wireguard-tools
    pkgs.exiftool
    pkgs.chafa
    pkgs.gophertube
    pkgs.lesspipe
    pkgs.hledger
    (
      (pkgs.buku.override {
        withServer = true;
      }).overrideAttrs
      (old: {
        doCheck = false;
        doInstallCheck = false;
        preCheck = (old.preCheck or "") + ''
          rm tests/test_{server,views}.py
        '';
      })
    )
    pkgs.dos2unix
    pkgs.bunbun
    pkgs.glow
    pkgs.just
    pkgs.typescript-language-server
    pkgs.typescript
    pkgs.ddgr
    pkgs.ncmpcpp
    pkgs.mpc
    pkgs.mpv
    pkgs.mpdscribble
    pkgs.nix-search-cli
    # pkgs.mplayer
    # pkgs.beets

    pkgs.pipes
    pkgs.cbonsai
    pkgs.tarts
    pkgs.macchina
    pkgs.cloudflared
    pkgs.hexyl
    pkgs.sd
    pkgs.stripe-cli
    pkgs.nix-du
    pkgs.nix-diff
    pkgs.captive-browser
    pkgs.oci-cli
    pkgs.grc
    pkgs.scooter
    pkgs.dua
    pkgs.procs
    pkgs.scc
    # pkgs.dix # FIXME: tests fail in sandbox on aarch64-darwin (path/symlink tests, /private/tmp). Re-enable when nixpkgs fixes checkPhase.
    pkgs.nix-tree
    pkgs.cachix
    pkgs.omnix
    inputs.xilo.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.sqlmap
    pkgs.dalfox
    pkgs.autoflake
    pkgs.autossh

    pkgs.pigz

    inputs.terminal-wakatime.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.late-sh.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Scripts
    (pkgs.writeShellScriptBin "aipick" ''
          set -e

      choice=$(
        printf "%s\n" ${lib.concatStringsSep " " (builtins.attrNames aiMap)} \
        | tr ' ' '\n' \
        | ${pkgs.fzf}/bin/fzf --prompt="AI > "
      )

      if [ -n "$choice" ]; then
        case "$choice" in
          ${lib.concatStringsSep "\n      " (
            map (name: "${name}) exec ${aiMap.${name}.bin} ;;") (builtins.attrNames aiMap)
          )}
        esac
      fi
    '')
    (pkgs.writeShellScriptBin "rfv" ''
      RELOAD='reload:rg --column --color=always --smart-case {q} || :'
      OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                $EDITOR {1} +{2}
              else
                $EDITOR +cw -q {+f}
              fi'
      fzf --disabled --ansi --multi \
          --bind "start:$RELOAD" --bind "change:$RELOAD" \
          --bind "enter:become:$OPENER" \
          --bind "ctrl-o:execute:$OPENER" \
          --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
          --delimiter : \
          --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
          --preview-window '~4,+{2}+4/3,<80(up)' \
          --query "$*"
    '')
    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })

    (pkgs.writeShellScriptBin "git-select-branch" ''
      if [ -d "./.git" ]; then
        git fetch
        selected_remote_branch=$(git branch -r | fzf | sed -e 's/^[[:space:]]*//')
        if [ -n "$selected_remote_branch" ]; then
          selected_branch=$(echo "$selected_remote_branch" | sed -e 's/origin\///');
          if git rev-parse --verify "$selected_branch" >/dev/null 2>&1; then
            git checkout "$selected_branch"
          else
            git checkout --track "$selected_remote_branch"
          fi
        else
          echo "Exit: You haven't selected a branch..."
        fi
      else
        echo "Error: There's no .git dir..."
        exit 1
      fi
    '')

    (pkgs.writeShellScriptBin "hackatime-summary" ''
      # Fixed variable escaping for Nix
      user_id=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.slack_user_id.path} 2>/dev/null || echo "")
      use_waka=false

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --waka) use_waka=true; shift ;;
          *) user_id="$1"; shift ;;
        esac
      done

      if [[ -z "$user_id" ]]; then
        user_id=$(${pkgs.gum}/bin/gum input --placeholder "Enter user ID" --prompt "User ID: ")
      fi

      [[ -z "$user_id" ]] && { ${pkgs.gum}/bin/gum style --foreground 196 "No user ID"; exit 1; }

      host=$([[ "$use_waka" = true ]] && echo "waka.hackclub.com" || echo "hackatime.hackclub.com")

      ${pkgs.gum}/bin/gum spin --spinner dot --title "Fetching from $host..." -- \
        ${pkgs.curl}/bin/curl -s -X 'GET' "https://$host/api/summary?user=''${user_id}&interval=month" \
        -H 'accept: application/json' \
        -H 'Authorization: Bearer 2ce9e698-8a16-46f0-b49a-ac121bcfd608' > /tmp/hackatime-$$.json

      total_seconds=$(${pkgs.jq}/bin/jq -r '(.categories + .projects | map(.total) | add) // 0' /tmp/hackatime-$$.json)

      if [[ "$total_seconds" -gt 0 ]]; then
        printf "Total: %dh %dm %ds\n" $((total_seconds/3600)) $(((total_seconds%3600)/60)) $((total_seconds%60))
      fi

      # Display lists
      ${pkgs.jq}/bin/jq -r '"\nTop Projects:", (.projects | sort_by(-.total)[0:5][] | "  \(.key): \(.total/3600|floor)h")' /tmp/hackatime-$$.json

      rm -f /tmp/hackatime-$$.json
    '')
    (pkgs.writeShellScriptBin "fip" ''
      if (( $# < 2 )); then
        echo "Usage: fip <host> <port1> [port2] ..."
        exit 1
      fi
      host="$1"
      shift
      for port in "$@"; do
        ${pkgs.openssh}/bin/ssh -f -N -L "$port:localhost:$port" "$host" && \
          echo "Forwarding localhost:$port -> $host:$port"
      done
    '')
    (pkgs.writeShellScriptBin "dip" ''
      if (( $# == 0 )); then
        echo "Usage: dip <port1> [port2] ..."
        exit 1
      fi
      for port in "$@"; do
        ${pkgs.procps}/bin/pkill -f "ssh.*-L $port:localhost:$port" && \
          echo "Stopped forwarding port $port" || \
          echo "No forwarding on port $port"
      done
    '')
    (pkgs.writeShellScriptBin "lip" ''
      ${pkgs.procps}/bin/pgrep -af "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "No active forwards"
    '')
    (pkgs.writeShellScriptBin "transcode-video-1080p" ''
      ${pkgs.ffmpeg}/bin/ffmpeg -i "$1" -vf scale=1920:1080 -c:v libx264 -preset fast -crf 23 -c:a copy "''${1%.*}-1080p.mp4"
    '')
    (pkgs.writeShellScriptBin "transcode-video-4K" ''
      ${pkgs.ffmpeg}/bin/ffmpeg -i "$1" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k "''${1%.*}-optimized.mp4"
    '')
    (pkgs.writeShellScriptBin "img2jpg" ''
      img="$1"
      shift
      ${pkgs.imagemagick}/bin/magick "$img" "$@" -quality 95 -strip "''${img%.*}-converted.jpg"
    '')
    (pkgs.writeShellScriptBin "img2jpg-small" ''
      img="$1"
      shift
      ${pkgs.imagemagick}/bin/magick "$img" "$@" -resize 1080x\> -quality 95 -strip "''${img%.*}-small.jpg"
    '')
    (pkgs.writeShellScriptBin "img2jpg-medium" ''
      img="$1"
      shift
      ${pkgs.imagemagick}/bin/magick "$img" "$@" -resize 1800x\> -quality 95 -strip "''${img%.*}-medium.jpg"
    '')
    (pkgs.writeShellScriptBin "img2png" ''
      img="$1"
      shift
      ${pkgs.imagemagick}/bin/magick "$img" "$@" -strip \
        -define png:compression-filter=5 \
        -define png:compression-level=9 \
        -define png:compression-strategy=1 \
        -define png:exclude-chunk=all \
        "''${img%.*}-optimized.png"
    '')
    (pkgs.writeShellScriptBin "gcomp" ''
            fzf \
          --disabled \
      --prompt "Google❯ " \
          --bind 'change:reload:Q=$(echo {q} | sed "s/ /+/g"); curl -s "https://suggestqueries.google.com/complete/search?client=firefox&q=$Q" 2>/dev/null | python3 -c "import sys,json; [print(s) for s in json.load(sys.stdin)[1]]" 2>/dev/null || true' \
          --height=30% \
          --border=rounded \
          --color=prompt:cyan \
          --print-query \
          < /dev/null
    '')
  ];
}
