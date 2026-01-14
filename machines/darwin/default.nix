{inputs, ...}: {
  nixpkgs = {
    overlays = [inputs.nix-topology.overlays.default inputs.lazygit.overlays.default       inputs.nur.overlays.default
];

    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      max-jobs = "auto";
      trusted-users = [
        "root"
        "avy"
        "@admin"
      ];
      extra-substituters = [
        "https://cache.numtide.com"
        # "ssh://eu.nixbuild.net"
        "https://colmena.cachix.org"
        "https://catppuccin.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nixbuild.net/OFT2JX-1:c0PQH1gJLM8bMKX5O1giRWxDUgpCpcpMrkYw6HCmprQ="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      ];
    };
    optimise = {
      automatic = true;
    };
    distributedBuilds = false;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        supportedFeatures = ["benchmark" "big-parallel"];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "aarch64-linux";
        maxJobs = 100;
        supportedFeatures = ["benchmark" "big-parallel"];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "armv7l-linux";
        maxJobs = 100;
        supportedFeatures = ["benchmark" "big-parallel"];
      }
      {
        hostName = "eu.nixbuild.net";
        system = "i686-linux";
        maxJobs = 100;
        supportedFeatures = ["benchmark" "big-parallel"];
      }
    ];
  };
  programs.nix-index.enable = true;
}
