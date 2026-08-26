{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  # helpers = import ../../flakeHelpers.nix inputs;
  sshKey = "${config.users.users.avy.home}/.ssh/avy";
in
{
  # nixpkgs = helpers.nixpkgsCfg;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = "auto";
      trusted-users = [
        "root"
        "avy"
        "@admin"
      ];
      log-lines = lib.mkDefault 25;
      max-free = lib.mkDefault (3000 * 1024 * 1024);
      min-free = lib.mkDefault (512 * 1024 * 1024);
      extra-substituters = [
        "https://cache.numtide.com"
        # "ssh-ng://eu.nixbuild.net"
        "https://catppuccin.cachix.org"
        "https://numtide.cachix.org"
        "https://nix-community.cachix.org"
        "https://fenix.cachix.org"
        "https://avycado13.cachix.org"
        "https://cache.avyay.in/c/default/main"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nixbuild.net/OFT2JX-1:c0PQH1gJLM8bMKX5O1giRWxDUgpCpcpMrkYw6HCmprQ="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="
        "avycado13.cachix.org-1:omae3JdfM9Oeri1fAPbWwqLhRbXmbs1tcI//1Hi48qs="
        "main:dQ6VTlBqbChv4jdFSjf2g9pmylkXFkQEaFXLHuzWfMM="
      ];

      connect-timeout = lib.mkDefault 5;
      fallback = true;
      builders-use-substitutes = true;
      auto-optimise-store = true;
      netrc-file = "/etc/nix/netrc";
      narinfo-cache-positive-ttl = 3600;
      # Runs as the nix-daemon (root), which has no ~/.config/cachix.
      # Point HOME at avy's home so xilo finds the auth token, and make
      # the push best-effort so a transient xilo/network failure can't
      # fail an otherwise-successful rebuild.
      post-build-hook = pkgs.writeShellScript "cache-push" ''
        set -eu

        export HOME=${config.users.users.avy.home}

        [ -n "''${OUT_PATHS:-}" ] || exit 0

        printf '%s\n' "''${OUT_PATHS}" \
          | ${
            lib.getExe inputs.xilo.packages.${pkgs.stdenv.hostPlatform.system}.default
          } push default/main - --quiet \
          || true
      '';
    };
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];
    registry.nixpkgs.flake = inputs.nixpkgs;
    optimise = {
      automatic = true;
    };
    gc = {
      automatic = true;
      options = "-d --delete-older-than 7d";
    };
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        # protocol = "ssh-ng";
        sshUser = "avycado13";
        sshKey = sshKey;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "aarch64-linux";
        maxJobs = 100;
        speedFactor = 10;
        # protocol = "ssh-ng";
        sshUser = "avycado13";
        sshKey = sshKey;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "armv7l-linux";
        maxJobs = 100;
        # protocol = "ssh-ng";
        sshUser = "avycado13";
        sshKey = sshKey;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "i686-linux";
        maxJobs = 100;
        # protocol = "ssh-ng";
        sshUser = "avycado13";
        sshKey = sshKey;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
    ];
  };
  programs.nix-index.enable = true;

  # Garnix binary cache netrc (sops, nixos only)
  sops.secrets.garnix_netrc = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0600";
    path = "/etc/nix/netrc";
  };
}
