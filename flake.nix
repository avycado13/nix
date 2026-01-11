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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    kubenix.url = "github:hall/kubenix";
    nixos-shell.url = "github:Mic92/nixos-shell";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    extra-container.url = "github:erikarvstedt/extra-container";
    extra-container.inputs.nixpkgs.follows = "nixpkgs";
    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xc = {
      url = "github:joerdav/xc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      # Use the same nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Optional: Declarative tap management
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
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral"; # Refers to the main branch and is updated to the latest commit when you use "nix flake update"
      flake = false;
    };
    nix-topology.url = "github:oddlama/nix-topology";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";
    brew-boring-notch = {
      url = "github:TheBoredTeam/homebrew-boring-notch";
      flake = false;
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    robotnix.url = "github:nix-community/robotnix";
    lazygit.url = "github:jesseduffield/lazygit";
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-auth.url = "github:numtide/nix-auth";
    terminal-wakatime = {
      url = "github:hackclub/terminal-wakatime";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena.url = "github:zhaofengli/colmena";
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };

  outputs = {...} @ inputs: let
    helpers = import ./flakeHelpers.nix inputs;
    inherit (helpers) mkMerge mkNixos mkDarwin;
  in
    mkMerge [
      (
        mkDarwin "Avys-Mac" inputs.nixpkgs
        []
        []
      )

      (mkNixos "pi1" inputs.nixpkgs "aarch64-linux" [] [inputs.nixos-hardware.nixosModules.raspberry-pi-3])
      (inputs.flake-utils.lib.eachDefaultSystem (
        system: let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [inputs.agenix-rekey.overlays.default];
          };
        in {
          formatter = pkgs.nixfmt-rfc-style;

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.nh
              pkgs.nixos-rebuild-ng
              pkgs.agenix-rekey
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";
            settings.global.excludes = [
              "*.lock"
              ".gitignore"
              "secrets/*"
            ];
            programs.nixfmt.enable = true;
            programs.nixfmt.package = pkgs.nixfmt-rfc-style;
            programs.deadnix.enable = true;
            programs.shellcheck.enable = true;
          };
        }
      ))
    ];
}
