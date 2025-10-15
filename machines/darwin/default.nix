{...}: {
  nixpkgs = {
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
    };
    optimise = {
      automatic = true;
    };
  };
}
