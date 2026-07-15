# vim: set ft=make :

# Show all available recipes interactively with fzf
choose:
    @just --list | grep -E '^\s+' | sed 's/^\s*//' | cut -d' ' -f1 | fzf --preview 'just --list | grep "^{}" | head -1' --reverse --height=50% | xargs just

update:
    nix flake update

build-iso $host:
    just copy {{ host }}; ssh {{ host }} "nix-shell -p nixos-generators.out --run 'nixos-generate -c /etc/nixos/machines/installer/default.nix -f install-iso -I nixpkgs=channel:nixos-25.11'"

check:
    nix flake check

dry-run $host:
    nixos-rebuild dry-activate --flake .#{{ host }} --target-host {{ host }} --build-host {{ host }} --fast --use-remote-sudo

deploy $host:
    just copy {{ host }}; nixos-rebuild switch --flake .#{{ host }} --target-host {{ host }} --build-host {{ host }} --no-reexec --sudo --elevate=sudo --ask-sudo-password

copy $host:
    rsync -ax --delete --rsync-path="rsync" ./ {{ host }}:/etc/nixos/

darwin-deploy:
    nh darwin switch .

home-deploy $host:
    just copy {{ host }}; ssh {{ host }} "cd /etc/nixos && home-manager switch --flake .#avy@{{ host }}"

home-dry-run $host:
    just copy {{ host }}; ssh {{ host }} "cd /etc/nixos && home-manager switch --flake .#avy@{{ host }} --dry-run"
