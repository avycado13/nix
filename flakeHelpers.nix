inputs:
let
  nixpkgsCfg = {
    overlays = [
      inputs.nix-topology.overlays.default
      inputs.lazygit.overlays.default
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      inputs.fenix.overlays.default
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
      };
      home-manager.users.avy.imports = [
        inputs.agenix.homeManagerModules.default
        inputs.nix-index-database.homeModules.nix-index
        inputs.catppuccin.homeModules.catppuccin
        inputs.try.homeModules.default
        ./users/avy/dots.nix
        ./users/avy/age.nix
      ]
      ++ (
        if (lib.hasSuffix "-darwin" system) then [ inputs.mac-app-util.homeManagerModules.default ] else [ ]
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
        inputs.agenix.darwinModules.default
        ./machines/darwin
        ./machines/darwin/${machineHostname}
        inputs.mac-app-util.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-index-database.darwinModules.nix-index
        inputs.virby.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
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
              "Sikarugir-App/sikarugir" = inputs.brew-sikarugir;
            };
            mutableTaps = true;
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

  mkNixos = machineHostname: nixpkgsVersion: hardware: extraHmModules: extraModules: {
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = hardware;
      specialArgs = { inherit inputs; };
      modules = [
        ./homelab
        ./machines/nixos/${machineHostname}
        ./modules/email
        inputs.nix-mineral.nixosModules.nix-mineral
        inputs.agenix.nixosModules.default
        inputs.nix-topology.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nixos-shell.nixosModules.nixos-shell
        inputs.nix-minecraft.nixosModules.minecraft-servers
        inputs.home-manager.nixosModules.home-manager
        { programs.nix-index-database.comma.enable = true; }
        ./users/avy
        (homeManagerCfg {
          userPackages = true;
          system = hardware;
          extraImports = extraHmModules;
          lib = nixpkgsVersion.lib;
        })
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
        inputs.agenix.homeManagerModules.default
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
