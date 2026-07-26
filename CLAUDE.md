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

## Codebase Structure

```
flake.nix               # Entry point; calls mkDarwin/mkNixos per host (Avys-Mac, pi0, pi1, oracle, eclipse, gce)
flakeHelpers.nix         # mkDarwin, mkNixos, mkHome, mkColmena, mkMerge, nixpkgsCfg — read first for new machines
machines/
  darwin/
    default.nix          # shared settings for all Darwin machines
    Avys-Mac/             # host-specific config + ricing.nix, system.nix
  nixos/
    default.nix           # shared settings for all NixOS machines (imports modules/nix, binary caches, ssh/sudo defaults)
    <hostname>/default.nix # host-specific config; extras like disko.nix, facter.json, hardware-configuration.nix live alongside
    pi1/homelab.nix        # example of a host opting into the homelab (sets homelab.enable + homelab.services.*)
modules/                  # reusable NixOS modules: ddns, email, binaryCache, remoteBuild, nix, secrets
homelab/                  # imported into every NixOS system via mkNixos, inert unless homelab.enable is set
  default.nix              # top-level homelab.* options (group, timeZone, baseDomainName, cloudflare creds, email, notifications)
  services/
    default.nix            # homelab.services.enable, shared Caddy/ACME wiring, notify-failure@ template unit, imports every service dir
    <service>/default.nix  # one service per directory (see "Adding a Homelab Service" below)
  fail2ban-cloudflare/     # bans offenders at the Cloudflare edge
  motd/                    # login MOTD listing enabled/monitored services
users/avy/
  default.nix              # NixOS user declaration (uid, groups, shell, ssh key)
  packages.nix             # all user packages, including AI/LLM CLI tools from inputs.llm-agents and custom shell scripts
  dots.nix                 # imports dotfile modules from dotfiles/<feature>/
  sops.nix                 # per-user sops secret declarations
  dotfiles/<feature>/      # browser, devenv, editor, email, git, gpg, ssh, syncthing, terminal, theme, zellij, zsh
secrets/                  # sops-encrypted secrets.yaml (default) and services.yaml — never commit plaintext
```

## Architecture

**`flakeHelpers.nix`** is the core abstraction. Defines `mkDarwin`, `mkNixos`, `mkHome`, `mkColmena`, `mkMerge`, and `nixpkgsCfg`. All system configs in `flake.nix` go through these builders (`flake.nix` currently only calls `mkDarwin` and `mkNixos`; `mkHome`/`mkColmena` exist as unused-but-available helpers). Read this file first when adding a new machine or understanding how inputs wire together.

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

**Homelab** (`homelab/`) — imported directly into every NixOS system (`mkNixos` always includes `./homelab`), gated behind `homelab.enable`/`homelab.services.enable` so it's inert unless a host opts in (currently only `pi1` does, via `machines/nixos/pi1/homelab.nix`). Reverse proxy is **Caddy** (not Traefik), with ACME via `security.acme` (cloudflare DNS challenge). Currently active services (see `homelab/services/default.nix` imports): `miniflux`, `auth` (indiko + lldap), `glance`, `uptime-kuma`, `speedtest-tracker`, `xilo`, `retrom`. Commented-out/disabled: `ntfy`, `healthchecks`, `scrutiny`, `restic`. A `postgres` service dir provides shared DB setup for services that need it. `homelab/motd` builds a login MOTD listing enabled/monitored services; `homelab/fail2ban-cloudflare` bans offenders at the Cloudflare edge.

## Adding a Homelab Service

Each service lives in its own directory under `homelab/services/<name>/default.nix`, defines its own `options.homelab.services.<name>`, and is wired into the shared Caddy reverse proxy. There is no shared `mkService` factory — copy an existing service (`homelab/services/uptime-kuma/default.nix` is the simplest example) and adapt it. Pattern:

```nix
{ config, lib, ... }:
let
  service = "myservice";
  hl = config.homelab;
  cfg = hl.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";
    url = lib.mkOption {
      type = lib.types.str;
      default = "myservice.${hl.baseDomainName}";
      description = "Domain to serve myservice on";
    };
    # Optional: surface a bookmark/monitor entry on the Glance dashboard.
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "My Service";
    };
    glance.url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "https://${cfg.url}";
      description = "URL to show for this service in the Glance homelab bookmarks";
    };
  };

  config = lib.mkIf cfg.enable {
    services.${service}.enable = true; # or hand-roll a systemd unit / container

    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:PORT
      '';
    };

    # Optional: page on failure via ntfy, matching the shared template unit.
    systemd.services.${service}.serviceConfig.OnFailure = lib.mkIf (
      hl.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
```

Then:
1. Add `./<name>` to the `imports` list in `homelab/services/default.nix`.
2. Enable it on a host, e.g. in `machines/nixos/pi1/homelab.nix`: `homelab.services.<name>.enable = true;` plus any required options.
3. Feed secrets (API keys, credentials files) through sops — add them to `secrets/services.yaml` and reference the decrypted path via `config.sops.secrets.<name>.path` or `config.sops.templates`, never inline. See `homelab/services/retrom/default.nix` for an example using `sops.templates` to render a JSON config file containing secrets (avoids writing them to the Nix store in plaintext, unlike `pkgs.writeText`-based `settings` options some upstream modules expose).
4. If the service should appear on the homelab Glance dashboard, define `glance.name`/`glance.url`/`glance.description` options as above — `homelab/services/glance/default.nix` auto-collects bookmarks from any `homelab.services.*` with `enable = true` and a non-null `glance.url`.
5. Run `treefmt` and `nix flake check` before committing.

## Key Patterns

- **Secrets**: `sops-nix`, not agenix. Encrypted files in `secrets/secrets.yaml` (default) and `secrets/services.yaml`; recipients defined in `.sops.yaml` (age keys `avy`/`pi1`, a GPG key, and an AWS KMS key). Age key file at `~/.config/sops/age/keys.txt` plus host SSH host keys are used to decrypt (`modules/secrets/default.nix`). Never commit plaintext secrets.
- **nixpkgs config**: `allowUnfree = true`, overlays for nix-topology, lazygit, NUR, nix-vscode-extensions, fenix, an ollama MLX-backend-disable patch — applied uniformly via `nixpkgsCfg` in `flakeHelpers.nix`.
- **Binary caches / substituters**: numtide, colmena, catppuccin, virby, nix-community, garnix, fenix, avycado13 — configured in `modules/nix/default.nix`, shared by all NixOS hosts.
- **state version**: `"25.05"` across all systems.

## Formatting

`treefmt` is the single formatter. It runs nixfmt, deadnix, and shellcheck. Run it before committing. Exclusions: `*.lock`, `.gitignore`, `secrets/*`.
