# AGENTS.md

This document helps AI agents work effectively in this NixOS/Nix-Darwin configuration repository.

## Project Overview

This is a Nix flake-based configuration for managing multiple systems:

- NixOS systems (e.g., Raspberry Pi)
- macOS (Darwin) systems (e.g., Avy's MacBook)
- Uses home-manager for user configurations
- Includes homelab services and modules

## Essential Commands

### Flake Management

- `nix flake update`: Update all flake inputs to their latest versions
- `nix flake check`: Validate flake configuration and check for errors

### Building and Deploying

- `just deploy <host>`: Deploy configuration to a NixOS host (copies files via rsync, then switches)
- `just dry-run <host>`: Test deployment without applying changes
- `sudo darwin-rebuild switch --flake .`: Apply Darwin configuration on macOS
- `just darwin-deploy`: Shorthand for Darwin rebuild (from Justfile)

### Development Shell

Enter the dev shell for tools:

```bash
nix develop
```

Available tools: just, nh, nixos-rebuild-ng, agenix-rekey

## Code Organization

### Directory Structure

- `flake.nix`: Main flake definition with inputs and outputs
- `flakeHelpers.nix`: Helper functions for creating system configurations
- `machines/`: System-specific configurations
  - `darwin/`: macOS configurations
  - `nixos/`: NixOS configurations
- `homelab/`: Homelab services (services/, modules/, motd/)
- `users/avy/`: User configuration (packages, dotfiles, etc.)
- `modules/`: Reusable NixOS modules (email, ddns, etc.)
- `secrets/`: Age-encrypted secrets (managed with agenix)

### Configuration Patterns

- Configurations use standard NixOS/Darwin module format
- Home-manager is integrated for user-specific settings
- Flake helpers (`mkDarwin`, `mkNixos`) standardize configuration creation
- Secrets are managed via agenix (`.age` files in `secrets/`)

## Development Workflow

1. Make changes to configuration files
2. Test with `just dry-run <host>` for NixOS or local rebuild for Darwin
3. Format code: `treefmt` (automatically configured)
4. Commit and deploy with `just deploy <host>`

## Formatting and Linting

- **Formatter**: `nixfmt` (configured in flake.nix)
- **Linting**: `deadnix` (detects unused code), `shellcheck` (shell scripts)
- **Auto-format**: Run `treefmt` to format all files
- Exclusions: `*.lock`, `.gitignore`, `secrets/*`

## Gotchas

- **State Version**: Always set `system.stateVersion` appropriately (currently "25.05")
- **Agenix**: Secrets are in `secrets/` directory, managed with `agenix` tool
- **Home Directory**: Darwin configs set `homeDirectory = "/Users/avy"`
- **Mutable Users**: Some configs disable mutable users for security
- **Imports**: Configurations import from parent directories (e.g., `./homelab`, `./users/avy`)
- **Hardware Modules**: NixOS configs may include hardware-specific modules (e.g., `nixos-hardware.nixosModules.raspberry-pi-3`)

## Secrets Management

- Uses `agenix` for encrypted secrets
- Secret files: `.age` files in `secrets/`
- Public keys: Managed in `users/avy/age.nix`
- Rekey tool: `agenix-rekey` available in dev shell

## Testing

- No automated unit tests currently
- Manual testing via `dry-run` commands
- `test.sh`: Script for updating Bun package hashes (not related to config testing)
