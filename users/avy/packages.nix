{
  pkgs,
  ...
}: {
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    pkgs.neofetch
    pkgs.git-extras
    pkgs.devenv
    pkgs.manix
    pkgs.pnpm

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
   

  ];
}
