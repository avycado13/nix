{
  pkgs,
  inputs,
  config,
  ...
}: let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
  ]);
  zmx = import ../../packages/zmx.nix {
    inherit pkgs;
    inherit (pkgs) lib stdenv fetchurl autoPatchelfHook;
  };
  ai = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    # ai tools
    # opencode
    # gemini-cli
    qwen-code
    amp
    copilot-cli
    crush
  ];
in {
  home.packages =
    ai
    ++ [
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.
      zmx
      # pkgs.hello

      # stuff for normal peeps
      pkgs.onefetch
      pkgs.git-extras
      pkgs.devenv
      pkgs.manix
      pkgs.pnpm
      pkgs.nodejs-slim
      pkgs.magic-wormhole
      gdk
      pkgs.curl
      pkgs.wget
      # pkgs.try
      pkgs.htop
      pkgs.tree
      pkgs.cowsay
      pkgs.file
      pkgs.which
      pkgs.gnused
      pkgs.gnutar
      pkgs.gawk
      pkgs.coreutils
      pkgs.wakatime-cli
      inputs.terminal-wakatime.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      (pkgs.writeShellScriptBin "rfv" ''
        RELOAD='reload:rg --column --color=always --smart-case {q} || :'
        OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  nvim {1} +{2}     # No selection. Open the current line in Neovim.
                else
                  nvim +cw -q {+f}  # Build quickfix list for the selected items.
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
      (pkgs.writeShellScriptBin "ns" ''
        nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history
      '')
      (pkgs.writeShellScriptBin "git-select-branch" ''
        if [ -d "./.git" ]; then
          git fetch
          selected_remote_branch=$(git branch -r | fzf | sed -e 's/^[[:space:]]*//')
          if [ -n "$selected_remote_branch" ]; then
            selected_branch=$(echo "$selected_remote_branch" | sed -e 's/origin\///');
            if git rev-parse --verify "$selected_branch"; then
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
      (pkgs.writeShellScriptBin "searchbrew" ''
        # Optional query argument
        QUERY="$1"
        # Get list of formulae and casks, casks are prefixed
        FORMULAE=$(brew formulae)
        CASKS=$(brew casks | sed 's|^|homebrew/cask/|')
        # Combine both lists
        PKGS=$(printf "%s\n%s" "$FORMULAE" "$CASKS")
        # Run fzf with preview
        INSTALL_PKGS=$(printf "%s\n" "$PKGS" \
            | fzf --multi --preview='HOMEBREW_COLOR=1 brew info {}' \
                  --query="$QUERY" \
                  --nth=-1 \
                  --with-nth=-2.. \
                  --delimiter=/)
        # Check if user made a selection
        if [ -n "$INSTALL_PKGS" ]; then
            echo "$INSTALL_PKGS" | xargs brew install
        else
            echo "Nothing to install…"
        fi
      '')
      (pkgs.writeShellScriptBin "hackatime-summary" ''
        # shamelessly stolen from dunkirk.sh
        # Hackatime summary
        user_id=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.slack_user_id.path})
        use_waka=false

        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --waka)
              use_waka=true
              shift
              ;;
            *)
              user_id="$1"
              shift
              ;;
          esac
        done

        if [[ -z "$user_id" ]]; then
          user_id=$(${pkgs.gum}/bin/gum input --placeholder "Enter user ID" --prompt "User ID: ")
          if [[ -z "$user_id" ]]; then
            ${pkgs.gum}/bin/gum style --foreground 196 "No user ID provided"
            exit 1
          fi
        fi

        if [[ "$use_waka" = true ]]; then
          host="waka.hackclub.com"
        else
          host="hackatime.hackclub.com"
        fi

        ${pkgs.gum}/bin/gum spin --spinner dot --title "Fetching summary from $host for $user_id..." -- \
          ${pkgs.curl}/bin/curl -s -X 'GET' \
            "https://$host/api/summary?user=''${user_id}&interval=month" \
            -H 'accept: application/json' \
            -H 'Authorization: Bearer 2ce9e698-8a16-46f0-b49a-ac121bcfd608' \
          > /tmp/hackatime-$$.json

        ${pkgs.gum}/bin/gum style --bold --foreground 212 "Summary for $user_id"
        echo

        # Extract and display total time
        total_seconds=$(${pkgs.jq}/bin/jq -r '
          if (.categories | length) > 0 then
            (.categories | map(.total) | add)
          elif (.projects | length) > 0 then
            (.projects | map(.total) | add)
          else
            0
          end
        ' /tmp/hackatime-$$.json)

        if [[ "$total_seconds" -gt 0 ]]; then
          hours=$((total_seconds / 3600))
          minutes=$(((total_seconds % 3600) / 60))
          seconds=$((total_seconds % 60))
          ${pkgs.gum}/bin/gum style --foreground 35 "Total time: ''${hours}h ''${minutes}m ''${seconds}s"
        else
          ${pkgs.gum}/bin/gum style --foreground 214 "No activity recorded"
        fi

        echo

        # Top projects
        ${pkgs.gum}/bin/gum style --bold "Top Projects:"
        ${pkgs.jq}/bin/jq -r '
          if (.projects | length) > 0 then
            .projects | sort_by(-.total) | .[0:10] | .[] |
            "  \(.key): \((.total / 3600 | floor))h \(((.total % 3600) / 60) | floor)m"
          else
            "  No projects"
          end
        ' /tmp/hackatime-$$.json

        echo

        # Top languages
        ${pkgs.gum}/bin/gum style --bold "Top Languages:"
        ${pkgs.jq}/bin/jq -r '
          if (.languages | length) > 0 then
            .languages | sort_by(-.total) | .[0:10] | .[] |
            "  \(.key): \((.total / 3600 | floor))h \(((.total % 3600) / 60) | floor)m"
          else
            "  No languages"
          end
        ' /tmp/hackatime-$$.json

        rm -f /tmp/hackatime-$$.json
      '')
    ];
}
