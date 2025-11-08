{...}: {
  programs = {
    ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "/Users/avy/.ssh/avy";
        };
        "gh" = {
          hostname = "github.com";
          user = "git";
          identityFile = "/Users/avy/.ssh/avy";
        };
        "hackclub.app" = {
          hostname = "hackclub.app";
          user = "avycado13";
          identityFile = "/Users/avy/.ssh/avy";
        };
        "*pi*.*" = {
          user = "pi";
          identityFile = "/Users/avy/.ssh/avy";
        };
        "hashbang" = {
          hostname = "de1.hashbang.sh";
          user = "avycado";
          identityFile = "/Users/avy/.ssh/avy";
        };
        "eu.nixbuild.net" = {
          hostname = "eu.nixbuild.net";
          user = "avy";
          identityFile = "/Users/avy/.ssh/avy";
        };
        # gh = lib.mkBefore {
        #   hostname = "github.com";
        #   identityFile = "/Users/avy/.ssh/avy";
        # };
      };
    };
  };
}
