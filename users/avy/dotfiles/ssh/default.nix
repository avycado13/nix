{ lib, config, ... }:
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
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "gh" = {
          hostname = "github.com";
          user = "git";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "hackclub.app" = {
          hostname = "hackclub.app";
          user = "avycado13";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "*pi*.*" = {
          user = "pi";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "hashbang" = {
          hostname = "de1.hashbang.sh";
          user = "avycado";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "eu.nixbuild.net" = {
          hostname = "eu.nixbuild.net";
          user = "avycado13";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
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
        "oracle" = {
          user = "root";
          hostname = "192.9.130.175";
        };
        "eclipse" = {
          user = "root";
          hostname = "n1.eclipsesystems.org";
          port = 25033;
        };
        "nest" = {
          user = "avycado13";
          hostname = "hackclub.app";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "club" = {

          user = "avycado13";
          hostname = "tilde.club";
          identityFile = "${config.home.homeDirectory}/.ssh/avy";
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

        # Host *
          # IPQoS throughput
          # ServerAliveInterval 60
          # ServerAliveCountMax 3
      '';
    };
  };
}
