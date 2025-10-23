{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "avycado13";
    userEmail = "108358183+avycado13@users.noreply.github.com.";
    aliases = {
      st = "status";
    };
    package = pkgs.gitFull;
    extraConfig = {
      # trailer "changeid" = {ww
      #   key = "Change-Id";
      # };
      color = {
        ui = "auto";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
      pull = {
        rebase = false;
      };
      url."git@github.com:".insteadOf = "https://github.com/";
      diff = {
        "sqlite3" = {
          binary = true;
          textconv = "echo .dump | sqlite3";
        };
      };
    };
  };
}
