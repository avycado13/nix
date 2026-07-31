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
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  homeManagerCfg =
    {
      userPackages,
      extraImports ? [ ],
      pkgs,
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
        if (pkgs.stdenv.isDarwin) then
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
          extraImports = extraHmModules;
          pkgs = inputs.nixpkgs.legacyPackages.${system};
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
        inputs.xilo.nixosModules.default
        inputs.nix-cache-beacon.nixosModules.default
        inputs.retrom.nixosModules.retrom
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
}
