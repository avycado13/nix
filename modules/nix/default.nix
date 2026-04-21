{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
# let
#   helpers = import ../../flakeHelpers.nix inputs;
# in
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
        "ssh-ng://eu.nixbuild.net"
        "https://colmena.cachix.org"
        "https://catppuccin.cachix.org"
        "https://virby-nix-darwin.cachix.org"
        "https://numtide.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.garnix.io"
        "fenix.cachix.org"
        "avycado13.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nixbuild.net/OFT2JX-1:c0PQH1gJLM8bMKX5O1giRWxDUgpCpcpMrkYw6HCmprQ="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
        "virby-nix-darwin.cachix.org-1:z9GiEZeBU5bEeoDQjyfHPMGPBaIQJOOvYOOjGMKIlLo="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="
        "avycado13.cachix.org-1:omae3JdfM9Oeri1fAPbWwqLhRbXmbs1tcI//1Hi48qs="
      ];

      connect-timeout = lib.mkDefault 5;
      fallback = true;
      builders-use-substitutes = true;
      auto-optimise-store = true;
      netrc-file = "/etc/nix/netrc";
      narinfo-cache-positive-ttl = 3600;
      post-build-hook = "${pkgs.cachix}/bin/cachix push avycado13";
    };
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
        sshUser = "avycado13";
        sshKey = "/Users/avy/.ssh/avy";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "aarch64-linux";
        maxJobs = 100;
        sshUser = "avycado13";
        sshKey = "/Users/avy/.ssh/avy";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "armv7l-linux";
        maxJobs = 100;
        sshUser = "avycado13";
        sshKey = "/Users/avy/.ssh/avy";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "i686-linux";
        maxJobs = 100;
        sshUser = "avycado13";
        sshKey = "/Users/avy/.ssh/avy";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
    ];
  };
  programs.nix-index.enable = true;

  # Agenix secrets for nixos only
  age.secrets = lib.mkIf (builtins.hasAttr "age" config) {
    garnix_netrc = {
      file = ../../secrets/garnix_netrc.age;
      owner = "root";
      group = "root";
      mode = "0600";
      path = "/etc/nix/netrc";
    };
  };
}
