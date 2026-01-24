inputs:
let
  nixpkgsCfg = {
    overlays = [
      inputs.nix-topology.overlays.default
      inputs.lazygit.overlays.default
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
  # System must be set separately as it's platform-specific
  # NixOS includes it via lib.nixosSystem(system=...)
  # Darwin/home-manager set it in their respective builders
  homeManagerCfg = userPackages: extraImports: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit inputs;
    };
    home-manager.users.avy.imports = [
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
in
{
  inherit nixpkgsCfg;
  mkDarwin = machineHostname: _nixpkgsVersion: extraHmModules: extraModules: {
    darwinConfigurations.${machineHostname} = inputs.darwin.lib.darwinSystem rec {
      # It is better to define 'system' here so it can be referenced via 'rec'
      system = "aarch64-darwin";

      specialArgs = { inherit inputs; };

      modules = [
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
      modules = [
        ./homelab
        # ./machines/nixos/_common
        ./machines/nixos/${machineHostname}
        ./modules/email
        # "${inputs.secrets}/default.nix"
        inputs.nix-mineral.nixosModules.nix-mineral
        # inputs.nixos-conf-editor.packages.${system}.nixos-conf-editor
        inputs.microvm.nixosModules.microvm
        inputs.agenix.nixosModules.default
        inputs.nix-topology.nixosModules.default
        # inputs
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nixos-shell.nixosModules.nixos-shell
        inputs.extra-container.nixosModules.default
        inputs.nix-search-tv.packages.x86_64-linux.default
        inputs.nix-minecraft.nixosModules.minecraft-servers
        {
          programs.nix-index-database.comma.enable = true;
        }
        ./users/avy
        (homeManagerCfg true extraHmModules)
        # Disabled facter for now - file access issues in pure nix eval
        # inputs.nixos-facter-modules.nixosModules.facter
        # {
        #   config.facter.reportPath = "${toString ./.}/machines/nixos/${machineHostname}/facter.json";
        # }
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
      extraSpecialArgs = { inherit inputs; };
    };
  };
  mkDebian = machineHostname: _nixpkgsVersion: _extraHmModules: extraModules: {
    systemConfigs.${machineHostname} = inputs.system-manager.lib.makeSystemConfig {
      modules = [
        ./modules/email
        ./users/avy

        (homeManagerCfg false [ ])
      ]
      ++ extraModules;
    };

    mkColemna = _system: _extraModules: {
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
  };
}
