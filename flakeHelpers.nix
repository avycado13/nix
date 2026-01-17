inputs: let
  homeManagerCfg = userPackages: extraImports: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit inputs;
    };
    home-manager.users.avy.imports =
      [
        inputs.agenix.homeManagerModules.default
        inputs.mac-app-util.homeManagerModules.default
        inputs.nix-index-database.homeModules.nix-index
        inputs.catppuccin.homeModules.catppuccin
        ./users/avy/dots.nix
        ./users/avy/age.nix
      ]
      ++ extraImports;
    home-manager.backupFileExtension = "bak";
    home-manager.useUserPackages = userPackages;
  };
in {
  mkDarwin = machineHostname: nixpkgsVersion: extraHmModules: extraModules: {
    darwinConfigurations.${machineHostname} = inputs.darwin.lib.darwinSystem rec {
      # It is better to define 'system' here so it can be referenced via 'rec'
      system = "aarch64-darwin";

      specialArgs = {inherit inputs;};

      modules =
        [
          inputs.agenix.darwinModules.default
          ./machines/darwin
          ./machines/darwin/${machineHostname}
          inputs.mac-app-util.darwinModules.default
          inputs.home-manager.darwinModules.home-manager
          inputs.nix-index-database.darwinModules.nix-index
          # inputs.catppuccin.darwinModules.catppuccin
          inputs.nix-homebrew.darwinModules.nix-homebrew

          # Inline module to handle packages and home-manager settings
          {
            home-manager.users.avy.home.homeDirectory = inputs.nixpkgs.lib.mkForce "/Users/avy";

            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = "avy";
              taps = {
                "homebrew/homebrew-core" = inputs.homebrew-core;
                "homebrew/homebrew-cask" = inputs.homebrew-cask;
                "TheBoredTeam/boring-notch" = inputs.brew-boring-notch;
              };
              mutableTaps = true;
              autoMigrate = true;
            };
          }

          # Merge your extra Home Manager config
          (homeManagerCfg true extraHmModules)
        ]
        ++ extraModules; # Ensure extraModules are actually appended
    };
  };
  mkNixos = machineHostname: nixpkgsVersion: hardware: extraHmModules: extraModules: {
    # apps = inputs.nixinate.nixinate.x86_64-linux self;
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = hardware;
      specialArgs = {
        inherit inputs;
        # vars = import ./machines/nixos/vars.nix;
      };
      modules =
        [
          ./homelab
          # ./machines/nixos/_common
          ./machines/nixos/${machineHostname}
          ./modules/email
          # "${inputs.secrets}/default.nix"
          # inputs.nix-mineral
          # inputs.nixos-conf-editor.packages.${system}.nixos-conf-editor
          inputs.microvm.nixosModules.microvm
          inputs.agenix.nixosModules.default
          inputs.nix-topology.nixosModules.default
          # inputs
          inputs.nix-index-database.nixosModules.nix-index
          {programs.nix-index-database.comma.enable = true;}
          inputs.nixos-shell.nixosModules.nixos-shell
          inputs.extra-container.nixosModules.default
          inputs.nix-search-tv.packages.x86_64-linux.default
          inputs.nix-minecraft.nixosModules.minecraft-servers
          {
            nixpkgs.overlays = [inputs.nix-minecraft.overlay inputs.lazygit.overlays.default];
          }
          ./users/avy
          (homeManagerCfg true extraHmModules)
          inputs.nixos-facter-modules.nixosModules.facter
          {config.facter.reportPath = ./machines/nixos/${machineHostname}/facter.json;}
          inputs.disko.nixosModules.disko
        ]
        ++ extraModules;
    };
  };

  mkKube = name: system: extraModules:
    inputs.kubenix.evalModules.${system} {
      module = {kubenix, ...}: {
        imports = [kubenix.modules.k8s] ++ extraModules;
      };
    };

  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) {};

  mkHome = hostname: username: homePath: nixpkgsVersion: extraHmModules: {
    homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgsVersion {system = builtins.currentSystem or "x86_64-linux";};
      modules =
        [
          inputs.agenix.homeManagerModules.default
          # inputs.nix-index-database.homeModules.default
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
      extraSpecialArgs = {inherit inputs;};
    };
  };
  mkDebian = machineHostname: nixpkgsVersion: extraHmModules: extraModules: {
    systemConfigs.${machineHostname} = inputs.system-manager.lib.makeSystemConfig {
      modules =
        [
          ./modules/email
          ./users/avy

          (homeManagerCfg false [])
        ]
        ++ extraModules;
    };

    mkColemna = system: extraModules: {
      colmenaHive = inputs.colmena.lib.makeHive {
        meta = {
          nixpkgs = import inputs.nixpkgs {
            system = "aarch64-darwin";
            overlays = [];
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
          };
        };
      };
    };
  };
}
