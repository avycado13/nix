# nix

avy's (avycado13) Nix configuration — a flake-based setup for managing macOS and NixOS systems with home-manager, homelab services, and encrypted secrets.

## Systems

| Host | Platform | Description |
|------|----------|-------------|
| `Avys-Mac` | `aarch64-darwin` | macOS (nix-darwin) |
| `pi0` | `aarch64-linux` | Raspberry Pi (aarch64) |
| `pi1` | `aarch64-linux` | Raspberry Pi 3 |
| `oracle` | `x86_64-linux` | NixOS server |
| `eclipse` | `x86_64-linux` | NixOS server |

## Structure

```
flake.nix            # Flake definition
flakeHelpers.nix     # mkDarwin / mkNixos helpers
machines/
  darwin/            # macOS configurations
  nixos/             # NixOS configurations (pi0, pi1, oracle, eclipse)
users/avy/           # User config & dotfiles (home-manager)
homelab/
  services/          # auth, glance, miniflux, ntfy, postgres, restic, ...
  motd/              # Message of the day
modules/             # Reusable modules (ddns, email, binary cache, remote build)
secrets/             # Age-encrypted secrets (agenix)
```

## Usage

Enter the dev shell:

```bash
nix develop
```

### Deploy

```bash
just deploy <host>     # Deploy to a NixOS host
just dry-run <host>    # Dry-run a NixOS deployment
just darwin-deploy     # Rebuild macOS config locally
just update            # nix flake update
just check             # nix flake check
```

### Formatting

```bash
treefmt
```

Uses `nixfmt`, `deadnix`, and `shellcheck`.

## Secrets

Managed with [agenix](https://github.com/ryantm/agenix) and [agenix-rekey](https://github.com/oddlama/agenix-rekey). Encrypted `.age` files live in `secrets/`.
