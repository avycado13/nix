{inputs, ...}: {
  nixpkgs = {
    overlays = [inputs.nix-topology.overlays.default inputs.lazygit.overlays.default];

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
      extra-substituters = ["https://cache.numtide.com" "ssh://eu.nixbuild.net"];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nixbuild.net/OFT2JX-1:c0PQH1gJLM8bMKX5O1giRWxDUgpCpcpMrkYw6HCmprQ="
      ];
    };
    optimise = {
      automatic = true;
    };
    distributedBuilds = true;
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
}
