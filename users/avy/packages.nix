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
    qwen-code
    amp
    copilot-cli
    crush
    mistral-vibe
    kilocode-cli
    goose-cli
    letta-code
    forge
    cursor-agent
    pi
    opencode
    gemini-cli
    nanocoder
    codex
    ccusage-amp
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
    pkgs.nur.repos.avycado13.zmx
    inputs.wakatime-ls.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Basic Utilities
    pkgs.onefetch
    pkgs.fastfetch
    pkgs.git-extras
    pkgs.devenv
    pkgs.caligula
    pkgs.manix
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
    pkgs.serie
    pkgs.nurl
    pkgs.which
    pkgs.gnused
    pkgs.gnutar
    pkgs.gawk
    pkgs.coreutils
    pkgs.wakatime-cli
    pkgs.cmus
    pkgs.gum
    pkgs.jq
    pkgs.duf
    pkgs.wireguard-tools
    pkgs.hledger
    pkgs.glow
    pkgs.just
    pkgs.typescript-language-server
    pkgs.typescript

    pkgs.pipes
    pkgs.cbonsai
    pkgs.tarts
    pkgs.macchina
    pkgs.cloudflared
    pkgs.hexyl
    pkgs.sd
    pkgs.stripe-cli

    inputs.terminal-wakatime.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default

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
      user_id=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.slack_user_id.path} 2>/dev/null || echo "")
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
