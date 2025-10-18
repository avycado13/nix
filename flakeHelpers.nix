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
        ./users/avy/dots.nix
        ./users/avy/age.nix
      ]
      ++ extraImports;
    home-manager.backupFileExtension = "bak";
    home-manager.useUserPackages = userPackages;
  };
in {
  mkDarwin = machineHostname: nixpkgsVersion: extraHmModules: extraModules: {
    darwinConfigurations.${machineHostname} = inputs.darwin.lib.darwinSystem {
      system = builtins.currentSystem or "aarch64-darwin"; # Default to ARM but can be overridden
      specialArgs = {
        inherit inputs;
      };
      modules = [
        # "${inputs.secrets}/default.nix"
        inputs.agenix.darwinModules.default
        ./machines/darwin
        ./machines/darwin/${machineHostname}
        inputs.mac-app-util.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
        # inputs.nix-search-tv.darwinModules.default
        inputs.nix-index-database.darwinModules.nix-index
        {programs.nix-index-database.comma.enable = true;}
        {
          home-manager.users.avy.home.homeDirectory = inputs.nixpkgs.lib.mkForce "/Users/avy";
        }
        (inputs.nixpkgs.lib.attrsets.recursiveUpdate (homeManagerCfg true extraHmModules) {
          })
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = false;

            # User owning the Homebrew prefix
            user = "avy";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "nikitabobko/tap" = inputs.brew-aerospace;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = true;

            autoMigrate = true;
          };
        }
      ];
    };
  };
  mkNixos = machineHostname: nixpkgsVersion: hardware: extraModules: rec {
    deploy.nodes.${machineHostname} = {
      hostname = machineHostname;
      profiles.system = {
        user = "root";
        sshUser = "avy";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.${machineHostname};
      };
    };
    # apps = inputs.nixinate.nixinate.x86_64-linux self;
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        vars = import ./machines/nixos/vars.nix;
      };
      modules =
        [
          ./homelab
          # ./machines/nixos/_common
          # ./machines/nixos/${machineHostname}
          ./modules/email
          "${inputs.secrets}/default.nix"
          "${inputs.nix-mineral}/nix-mineral.nix"
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
            nixpkgs.overlays = [inputs.nix-minecraft.overlay];
          }
          ./users/avy
          (homeManagerCfg false [])
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

  mkHome = username: homePath: nixpkgsVersion: extraHmModules: {
    homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgsVersion {system = builtins.currentSystem or "x86_64-linux";};
      modules =
        [
          inputs.agenix.homeManagerModules.default
          ./users/avy/dots.nix
        ]
        ++ extraHmModules;
      extraSpecialArgs = {inherit inputs;};
      configuration = {
        home.username = username;
        home.homeDirectory = homePath;
      };
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
  };
}
