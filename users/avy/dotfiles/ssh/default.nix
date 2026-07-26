{ lib, config, ... }:
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = lib.mkDefault false;
          AddKeysToAgent = lib.mkDefault "no";
          Compression = lib.mkDefault false;
          ServerAliveInterval = lib.mkDefault 0;
          ServerAliveCountMax = lib.mkDefault 3;
          HashKnownHosts = lib.mkDefault false;
          UserKnownHostsFile = lib.mkDefault "~/.ssh/known_hosts";
          ControlMaster = lib.mkDefault "no";
          ControlPath = lib.mkDefault "~/.ssh/master-%r@%n:%p";
          ControlPersist = lib.mkDefault "no";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "gh" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "hackclub.app" = {
          HostName = "hackclub.app";
          User = "avycado13";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "hashbang" = {
          HostName = "de1.hashbang.sh";
          User = "avycado";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "eu.nixbuild.net" = {
          HostName = "eu.nixbuild.net";
          User = "avycado13";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
          ServerAliveInterval = 60;
        };
        "robotimpose" = {
          User = "root";
          HostName = "lsd.segfault.net";
          SetEnv = {
            SECRET = "xrxplgOCICqAADhxKWtbhClK";
          };
        };
        "loudbind" = {
          User = "root";
          HostName = "lsd.segfault.net";
          SetEnv = {
            SECRET = "USQSiYZJlqmgqgzNsqfkdKtq";
          };
        };
        "oracle" = {
          User = "ubuntu";
          HostName = "192.9.245.222";
        };
        "eclipse" = {
          User = "root";
          HostName = "n1.eclipsesystems.org";
          Port = 25033;
        };
        "nest" = {
          User = "avycado13";
          HostName = "hackclub.app";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "club" = {
          User = "avycado13";
          HostName = "tilde.club";
          IdentityFile = "${config.home.homeDirectory}/.ssh/avy";
        };
        "pi1" = {
          User = "avy";
          HostName = "10.0.0.227";

        };
      };
      extraConfig = ''
        Host eu.nixbuild.net
          PubkeyAcceptedKeyTypes ssh-ed25519
          IPQoS throughput
      '';
    };
  };
}
