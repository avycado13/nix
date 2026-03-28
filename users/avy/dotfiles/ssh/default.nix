{ lib, ... }:
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = true;
      matchBlocks = {
        "*" = {
          forwardAgent = lib.mkDefault false;
          addKeysToAgent = lib.mkDefault "no";
          compression = lib.mkDefault false;
          serverAliveInterval = lib.mkDefault 0;
          serverAliveCountMax = lib.mkDefault 3;
          hashKnownHosts = lib.mkDefault false;
          userKnownHostsFile = lib.mkDefault "~/.ssh/known_hosts";
          controlMaster = lib.mkDefault "no";
          controlPath = lib.mkDefault "~/.ssh/master-%r@%n:%p";
          controlPersist = lib.mkDefault "no";
          identityFile = "/Users/avy/.ssh/avy";
        };
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
          user = "avycado13";
          identityFile = "/Users/avy/.ssh/avy";
          serverAliveInterval = 60;
        };
        "robotimpose" = {
          user = "root";
          hostname = "lsd.segfault.net";
          setEnv = {
            SECRET = "xrxplgOCICqAADhxKWtbhClK";
          };
        };
        "loudbind" = {

          user = "root";
          hostname = "lsd.segfault.net";
          setEnv = {
            SECRET = "USQSiYZJlqmgqgzNsqfkdKtq";
          };
        };
        # gh = lib.mkBefore {
        #   hostname = "github.com";
        #   identityFile = "/Users/avy/.ssh/avy";
        # };
      };
      extraConfig = ''
        Host eu.nixbuild.net
          PubkeyAcceptedKeyTypes ssh-ed25519
          IPQoS throughput
      '';
    };
  };
}
