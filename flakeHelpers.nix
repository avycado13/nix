inputs:
let
  mkOpts =
    system: module:
    inputs.unf.lib.json {
      inherit (inputs) self;
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      modules = [ module ];
    };

  nixpkgsCfg = {
    overlays = [
      inputs.nix-topology.overlays.default
      inputs.lazygit.overlays.default
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      inputs.fenix.overlays.default
      # ollama 0.30.x auto-enables the MLX Metal backend on aarch64-darwin,
      # which fails in the Nix sandbox (no xcrun/metal toolchain). Disable it
      # by passing -DOLLAMA_MLX_BACKENDS="" to cmake. This mirrors the upstream
      # nixpkgs fix (commit b195b40) until nixos-unstable advances past it.
      # The llama.cpp Metal backend is unaffected.
      (_final: prev: {
        ollama = prev.ollama.overrideAttrs (old: {
          preBuild =
            builtins.replaceStrings
              [ ''-DFETCHCONTENT_SOURCE_DIR_LLAMA_CPP="$TMPDIR/llama-cpp-src" \'' ]
              [
                ''
                  -DFETCHCONTENT_SOURCE_DIR_LLAMA_CPP="$TMPDIR/llama-cpp-src" \
                      -DOLLAMA_MLX_BACKENDS="" \''
              ]
              old.preBuild;
        });
      })
      (final: prev: {
        zjstatus = inputs.zjstatus.packages.${prev.system}.default;
      })
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  homeManagerCfg =
    {
      userPackages,
      system ? "aarch64-darwin",
      extraImports ? [ ],
      lib,
    }:
    {
      home-manager.useGlobalPkgs = false;
      home-manager.extraSpecialArgs = {
        inherit inputs;
        inherit mkOpts;
      };
      home-manager.users.avy.imports = [
        inputs.sops-nix.homeManagerModules.sops
        ./modules/secrets/home.nix
        inputs.nix-index-database.homeModules.nix-index
        inputs.catppuccin.homeModules.catppuccin
        inputs.try.homeModules.default
        ./users/avy/dots.nix
        ./users/avy/sops.nix
      ]
      ++ (
        if (lib.hasSuffix "-darwin" system) then
          [
            inputs.mac-app-util.homeManagerModules.default
          ]
        else
          [ ]
      )
      ++ extraImports;
      home-manager.backupFileExtension = "bak";
      home-manager.useUserPackages = userPackages;
    };
in
{
  inherit nixpkgsCfg;

  mkDarwin = machineHostname: _nixpkgsVersion: system: extraHmModules: extraModules: {
    darwinConfigurations.${machineHostname} = inputs.darwin.lib.darwinSystem {
      system = system;
      specialArgs = { inherit inputs; };
      modules = [
        ./machines/darwin
        ./machines/darwin/${machineHostname}
        inputs.sops-nix.darwinModules.sops
        ./modules/secrets
        inputs.mac-app-util.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-index-database.darwinModules.nix-index
        inputs.virby.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.srvos.nixosModules.mixins-terminfo
        {
          home-manager.users.avy.home.homeDirectory = inputs.nixpkgs.lib.mkForce "/Users/avy";
          nix-homebrew = {
            enable = true;
            enableRosetta = false;
            user = "avy";
            taps = {
              "homebrew/homebrew-core" = inputs.nixpkgs.legacyPackages.${system}.fetchFromGitHub {
                owner = "homebrew";
                repo = "homebrew-core";
                rev = inputs.homebrew-core.rev;
                hash = inputs.homebrew-core.narHash;
                name = "homebrew-core-tap";
              };
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "TheBoredTeam/homebrew-boring-notch" = inputs.brew-boring-notch;
              "Sikarugir-App/homebrew-sikarugir" = inputs.brew-sikarugir;
              "fenio/homebrew-tap" = inputs.brew-anylinuxfs-gui;
              "nohajc/homebrew-anylinuxfs" = inputs.brew-anylinuxfs;
              "slp/homebrew-krun" = inputs.brew-krun;
            };
            mutableTaps = false;
            autoMigrate = true;
          };
        }
        (homeManagerCfg {
          userPackages = true;
          system = system;
          extraImports = extraHmModules;
          lib = inputs.nixpkgs.lib;
        })
      ]
      ++ extraModules;
    };
  };

  mkNixos = machineHostname: nixpkgsVersion: hardware: _extraHmModules: extraModules: {
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = hardware;
      specialArgs = { inherit inputs; };
      modules = [
        ./homelab
        ./machines/nixos
        ./machines/nixos/${machineHostname}
        ./modules/email
        ./modules/ddns
        inputs.nix-mineral.nixosModules.nix-mineral
        inputs.sops-nix.nixosModules.sops
        ./modules/secrets
        inputs.nix-topology.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nix-minecraft.nixosModules.minecraft-servers
        inputs.home-manager.nixosModules.home-manager
        { programs.nix-index-database.comma.enable = true; }
        inputs.catppuccin.nixosModules.catppuccin
        inputs.srvos.nixosModules.mixins-terminfo
        {
          # home-manager.users.avy.home.stateVersion = "25.05";
        }
        # ./users/avy
        # (homeManagerCfg {
        # userPackages = true;
        # system = hardware;
        # extraImports = extraHmModules;
        # lib = nixpkgsVersion.lib;
        # })
        inputs.disko.nixosModules.disko
      ]
      ++ extraModules;
    };
    deploy.nodes.${machineHostname} = {
      hostname = machineHostname;
      profiles.system = {
        user = "root";
        path =
          inputs.deploy-rs.lib.${hardware}.activate.nixos
            inputs.self.nixosConfigurations.${machineHostname};
      };
    };
  };

  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };

  mkHome = _hostname: username: homePath: nixpkgsVersion: extraHmModules: {
    homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgsVersion { system = builtins.currentSystem or "x86_64-linux"; };
      modules = [
        inputs.sops-nix.homeManagerModules.sops
        ./modules/secrets/home.nix
        ./users/avy/sops.nix
        ./users/avy/dots.nix
        {
          home = {
            username = username;
            homeDirectory = homePath;
            stateVersion = "25.05";
          };
        }
      ]
      ++ extraHmModules;
      extraSpecialArgs = { inherit inputs; };
    };
  };

  mkDebian = machineHostname: _nixpkgsVersion: _extraHmModules: extraModules: {
    systemConfigs.${machineHostname} = inputs.system-manager.lib.makeSystemConfig {
      modules = [
        ./modules/email
        ./users/avy
        (homeManagerCfg {
          userPackages = false;
          system = "x86_64-linux";
          lib = inputs.nixpkgs.lib;
        })
      ]
      ++ extraModules;
    };
  };

  mkColmena = _system: _extraModules: {
    colmenaHive = inputs.colmena.lib.makeHive {
      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "aarch64-darwin";
          overlays = [ ];
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };
        };
      };
    };
  };
}
