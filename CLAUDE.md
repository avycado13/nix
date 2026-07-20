# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Nix flake managing multiple systems declaratively:
- **Avys-Mac** — Apple Silicon macOS (nix-darwin + home-manager + nix-homebrew)
- **pi0** — Raspberry Pi Zero 2W (NixOS, aarch64-linux, SD card image)
- **pi1** — Raspberry Pi 3 (NixOS, aarch64-linux, SD card image, runs the homelab)
- **oracle** — Oracle Cloud VM (NixOS, x86_64-linux)
- **eclipse** — NixOS, x86_64-linux (srvos server profile)
- **gce** — Google Compute Engine VM (NixOS, x86_64-linux, GCE image)

## Essential Commands

```bash
nix develop          # Enter dev shell (provides: just, nh, nixos-rebuild-ng, treefmt, sops, ssh-to-age, nil, cachix, nix-output-monitor)
treefmt              # Format all files (nixfmt + deadnix + shellcheck)
nix flake check      # Validate flake

just darwin-deploy               # Apply Darwin config on this Mac (nh darwin switch)
just dry-run <host>              # Test NixOS deploy without applying
just deploy <host>               # rsync + nixos-rebuild switch to NixOS host
just copy <host>                 # rsync only (no rebuild)
just home-deploy <host>          # rsync + home-manager switch on a remote host
just update                      # nix flake update
```

## Architecture

**`flakeHelpers.nix`** — The core abstraction. Defines `mkDarwin`, `mkNixos`, `mkHome`, `mkColmena`, `mkMerge`, and `nixpkgsCfg`. All system configs in `flake.nix` go through these builders (`flake.nix` currently only calls `mkDarwin` and `mkNixos`; `mkHome`/`mkColmena` exist as unused-but-available helpers). Read this file first when adding a new machine or understanding how inputs wire together.

**Layered machine configs:**
- `machines/<type>/default.nix` — shared settings for all machines of that type (nix settings, binary caches, ssh/sudo defaults)
- `machines/<type>/<hostname>/default.nix` — host-specific config (e.g. `machines/nixos/pi1/homelab.nix` wires up the homelab on that host)
- Machine-specific extras (e.g., `ricing.nix`, `system.nix`, `disko.nix`, `facter.json`) imported by the host config

**User environment** — entirely in `users/avy/`:
- `packages.nix` — all user packages including many AI/LLM CLI tools (from `inputs.llm-agents`) and custom shell scripts
- `dots.nix` — imports dotfile modules from `dotfiles/<feature>/` (browser, devenv, editor, email, git, gpg, ssh, syncthing, terminal, theme, zellij, zsh)
- `default.nix` — NixOS user declaration (uid, groups, shell, ssh key)
- `sops.nix` — per-user sops secret declarations (paths, modes, which sops file each secret comes from)

**Modules** (`modules/`) — reusable NixOS modules: `ddns` (cloudflare/desec/duckdns/freedns), `email`, `binaryCache`, `remoteBuild`, `nix` (core nix settings + substituters, imported by `machines/nixos/default.nix`), `secrets` (wires sops-nix, see below).

**Homelab** (`homelab/`) — imported directly into every NixOS system (`mkNixos` always includes `./homelab`), gated behind `homelab.enable`/`homelab.services.enable` so it's inert unless a host opts in (currently only `pi1` does, via `machines/nixos/pi1/homelab.nix`). Services live under `homelab/services/<name>/default.nix`, each defining its own `options.homelab.services.<name>` and wiring a `services.caddy.virtualHosts` block — there is no shared `mkService` factory anymore. Reverse proxy is **Caddy** (not Traefik), with ACME via `security.acme` (cloudflare DNS challenge). Currently active services (see `homelab/services/default.nix` imports): `miniflux`, `auth` (indiko + lldap), `glance`, `uptime-kuma`, `speedtest-tracker`. Commented-out/disabled: `ntfy`, `healthchecks`, `scrutiny`, `restic`. `postgres` service dirs also exist. `homelab/motd` builds a login MOTD listing enabled/monitored services; `homelab/fail2ban-cloudflare` bans offenders at the Cloudflare edge.

## Key Patterns

- **Secrets**: `sops-nix`, not agenix. Encrypted files in `secrets/secrets.yaml` (default) and `secrets/services.yaml`; recipients defined in `.sops.yaml` (age keys `avy`/`pi1`, a GPG key, and an AWS KMS key). Age key file at `~/.config/sops/age/keys.txt` plus host SSH host keys are used to decrypt (`modules/secrets/default.nix`). Never commit plaintext secrets.
- **nixpkgs config**: `allowUnfree = true`, overlays for nix-topology, lazygit, NUR, nix-vscode-extensions, fenix, an ollama MLX-backend-disable patch, and zjstatus — applied uniformly via `nixpkgsCfg` in `flakeHelpers.nix`.
- **Binary caches / substituters**: numtide, colmena, catppuccin, virby, nix-community, garnix, fenix, avycado13 — configured in `modules/nix/default.nix`, shared by all NixOS hosts.
- **state version**: `"25.05"` across all systems.

## Formatting

`treefmt` is the single formatter. It runs nixfmt, deadnix, and shellcheck. Run it before committing. Exclusions: `*.lock`, `.gitignore`, `secrets/*`.
