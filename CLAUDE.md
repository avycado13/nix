# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Nix flake managing multiple systems declaratively:
- **Avys-Mac** — Apple Silicon macOS (nix-darwin + home-manager + nix-homebrew)
- **pi0** — Raspberry Pi Zero 2W (NixOS, aarch64-linux, SD card image)
- **oracle** — Oracle Cloud VM (NixOS, x86_64-linux)

## Essential Commands

```bash
nix develop          # Enter dev shell (provides: just, nh, agenix, agenix-rekey, nil)
treefmt              # Format all files (nixfmt + deadnix + shellcheck)
nix flake check      # Validate flake

just darwin-deploy               # Apply Darwin config on this Mac
just dry-run <host>              # Test NixOS deploy without applying
just deploy <host>               # rsync + nixos-rebuild switch to NixOS host
just copy <host>                 # rsync only (no rebuild)
just update                      # nix flake update
```

## Architecture

**`flakeHelpers.nix`** — The core abstraction. Defines `mkDarwin`, `mkNixos`, `mkDebian`, `mkColmena`, and `nixpkgsCfg`. All system configs in `flake.nix` go through these builders. Read this file first when adding a new machine or understanding how inputs wire together.

**Layered machine configs:**
- `machines/<type>/default.nix` — shared settings for all machines of that type (nix settings, binary caches, nixbuild.net remote builds)
- `machines/<type>/<hostname>/default.nix` — host-specific config
- Machine-specific extras (e.g., `sketchybar.nix`, `system.nix`) imported by the host config

**User environment** — entirely in `users/avy/`:
- `packages.nix` — all user packages including many AI/LLM CLI tools and custom shell scripts (`rfv`, `ns`, `aipick`, `gcomp`, etc.)
- `dots.nix` — imports dotfile modules from `dotfiles/<feature>/`
- `default.nix` — NixOS user declaration (uid, groups, shell, ssh key)
- `age.nix` — agenix public key definitions

**Modules** (`modules/`) — reusable NixOS modules: ddns (cloudflare/duckdns/freedns), email, binaryCache, remoteBuild, nix config.

**Homelab** (`homelab/`) — containerized services with a `mkService` factory pattern. Services: auth (indiko+lldap), postgres, miniflux, bentopdf, upsnap. Reverse proxy via Traefik. Options defined in `homelab/default.nix`.

## Key Patterns

- **Secrets**: `agenix` — encrypted `.age` files in `secrets/`, keys in `users/avy/age.nix`. Never commit plaintext secrets.
- **nixpkgs config**: `allowUnfree = true`, overlays for nix-topology, lazygit, NUR, fenix, nix-vscode-extensions — applied uniformly via `nixpkgsCfg` in flakeHelpers.
- **Binary caches**: numtide, colmena, catppuccin, virby, nix-community, garnix — configured identically on Darwin and NixOS in the shared machine defaults.
- **Remote builds**: nixbuild.net (`eu.nixbuild.net`) supports x86_64, aarch64, armv7l, i686.
- **state version**: `"25.05"` across all systems.

## Formatting

`treefmt` is the single formatter. It runs nixfmt, deadnix, and shellcheck. Run it before committing. Exclusions: `*.lock`, `.gitignore`, `secrets/*`.
