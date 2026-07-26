{
  description = "avy's (avycado13) nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    mac-app-util.url = "github:hraban/mac-app-util";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral"; # Refers to the main branch and is updated to the latest commit when you use "nix flake update"
    };
    nix-topology.url = "github:oddlama/nix-topology";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";
    brew-boring-notch = {
      url = "github:TheBoredTeam/homebrew-boring-notch";
      flake = false;
    };
    brew-sikarugir = {
      url = "github:Sikarugir-App/homebrew-sikarugir";
      flake = false;
    };
    catppuccin.url = "github:catppuccin/nix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    lazygit.url = "github:jesseduffield/lazygit";
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-auth.url = "github:numtide/nix-auth";
    terminal-wakatime = {
      url = "github:hackclub/terminal-wakatime";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena.url = "github:zhaofengli/colmena";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    weechat-scripts = {
      url = "github:weechat/scripts";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wakatime-ls.url = "github:mrnossiom/wakatime-ls";
    wakatime-ls.inputs.nixpkgs.follows = "nixpkgs";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    virby.url = "github:quinneden/virby-nix-darwin/be170bd7ef21ce9773e7daa646d43f5405a1bdb2";
    srvos.url = "github:nix-community/srvos";
    gws-cli.url = "github:googleworkspace/cli";
    unf = {
      url = "git+https://git.atagen.co/atagen/unf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    try.url = "github:tobi/try";
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-anylinuxfs-gui = {
      url = "github:fenio/homebrew-tap";
      flake = false;
    };
    brew-anylinuxfs = {
      url = "github:nohajc/homebrew-anylinuxfs";
      flake = false;
    };
    brew-krun = {
      url = "github:slp/homebrew-krun";
      flake = false;
    };
    xilo.url = "github:stubbedev/xilo";
    nix-cache-beacon.url = "github:adisbladis/nix-cache-beacon";
    devour-flake = {
      url = "github:srid/devour-flake";
      flake = false;
    };
    # Don't follow root nixpkgs: retrom's package.nix pins fetchPnpmDeps
    # fetcherVersion = 3, which newer nixpkgs has dropped support for.
    # Let it build against its own (older) locked nixpkgs instead.
    retrom = {
      url = "github:JMBeresford/retrom/latest";
    };
  };

  outputs =
    { ... }@inputs:
    let
      helpers = import ./flakeHelpers.nix inputs;
      inherit (helpers)
        mkMerge
        mkDarwin
        mkNixos
        ;
    in
    mkMerge [
      (mkDarwin "Avys-Mac" inputs.nixpkgs "aarch64-darwin"
        [ ]
        [
          # {
          #   nix.distributedBuilds = true;
          #   nix.buildMachines = [
          #     {
          #       hostName = "localhost";
          #       sshUser = "builder";
          #       sshKey = "/etc/nix/builder_ed25519";
          #       system = linuxSystem;
          #       maxJobs = 4;
          #       supportedFeatures = [
          #         "kvm"
          #         "benchmark"
          #         "big-parallel"
          #       ];
          #     }
          #   ];

          #   launchd.daemons.darwin-builder = {
          #     command = "${darwin-builder.config.system.build.macos-builder-installer}/bin/create-builder";
          #     serviceConfig = {
          #       KeepAlive = true;
          #       RunAtLoad = true;
          #       StandardOutPath = "/var/log/darwin-builder.log";
          #       StandardErrorPath = "/var/log/darwin-builder.log";
          #     };
          #   };
          # }
        ]
      )

      (mkNixos "pi0" inputs.nixpkgs "aarch64-linux"
        [ ]
        [
          "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ]
      )

      (mkNixos "pi1" inputs.nixpkgs "aarch64-linux"
        [ ]
        [
          "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          inputs.nixos-hardware.nixosModules.raspberry-pi-3
        ]
      )

      (mkNixos "oracle" inputs.nixpkgs "x86_64-linux"
        [ ]
        [
          inputs.srvos.nixosModules.server
          "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
        ]
      )
      (mkNixos "eclipse" inputs.nixpkgs "x86_64-linux"
        [ ]
        [
          inputs.srvos.nixosModules.server
        ]
      )
      (mkNixos "gce" inputs.nixpkgs "x86_64-linux"
        [ ]
        [
          inputs.srvos.nixosModules.server
          "${inputs.nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
        ]
      )

      {
        # Per-host SSH connection overrides for deploy-rs — mkNixos defaults
        # `hostname` to the flake attr name, which isn't a resolvable
        # address/alias for these hosts. Merged over the deploy.nodes.* set
        # by mkNixos via mkMerge's recursiveUpdate, so profiles.system.path
        # (already correct) is left untouched.
        deploy.nodes.oracle = {
          hostname = "192.9.130.175";
          sshUser = "root";
        };
        deploy.nodes.eclipse = {
          hostname = "n1.eclipsesystems.org";
          sshUser = "root";
          sshOpts = [
            "-p"
            "25033"
          ];
        };
        deploy.nodes.pi1 = {
          hostname = "10.0.0.227";
          sshUser = "avy";
        };
      }
      {
        overlays.default = _final: prev: {
          devour-flake = prev.callPackage inputs.devour-flake { };
        };
      }

      (inputs.flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
          };
          treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.deadnix.enable = true;
            programs.shellcheck.enable = true;
          };
        in
        {
          formatter = treefmtEval.config.build.wrapper;
          checks.formatting = treefmtEval.config.build.check inputs.self;
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.nh
              pkgs.nixos-rebuild-ng
              treefmtEval.config.build.wrapper
              pkgs.sops
              pkgs.ssh-to-age
              pkgs.nil
              pkgs.cachix
              pkgs.nix-output-monitor
              inputs.deploy-rs.packages.${system}.default
              inputs.xilo.packages.${system}.default
              pkgs.devour-flake
              (pkgs.writeShellApplication {
                name = "nix-build-all";
                runtimeInputs = [
                  pkgs.nix
                  pkgs.devour-flake
                ];
                text = ''
                  # Make sure that flake.lock is sync
                  nix flake lock --no-update-lock-file

                  # Do a full nix build (all outputs)
                  # This uses https://github.com/srid/devour-flake
                  devour-flake . "$@"
                '';
              })
            ];
          };
        }
      ))
      {
        nixConfig = {
          extra-substituters = [ "https://cache.avyay.in/c/default/main" ];
          extra-trusted-public-keys = [ "main:dQ6VTlBqbChv4jdFSjf2g9pmylkXFkQEaFXLHuzWfMM=" ];
        };

      }
      {
        checks = builtins.mapAttrs (
          _system: deployLib: deployLib.deployChecks inputs.self.deploy
        ) inputs.deploy-rs.lib;
      }
    ];
}
