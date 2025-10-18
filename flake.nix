{
  description = "avy's (avycado13) nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    musnix = {url = "github:musnix/musnix";};
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral"; # Refers to the main branch and is updated to the latest commit when you use "nix flake update"
      flake = false;
    };
    nix-topology.url = "github:oddlama/nix-topology";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";
    brew-aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs = {...} @ inputs: let
    helpers = import ./flakeHelpers.nix inputs;
    inherit (helpers) mkMerge mkNixos mkDarwin mkHome;
  in
    mkMerge [
      (
        mkDarwin "Avys-Mac" inputs.nixpkgs
        [
        ]
        []
        mkHome "nest" "/home/avycado13" inputs.nixpkgs []
      )
    ];
}
