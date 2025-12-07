{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homelab.services.auth;
in {
  options.homelab.services.auth = {
    enable = lib.mkEnableOption "Auth Services";
  };
  config = lib.mkIf config.homelab.services.auth.enable {
    cfg.pocketid = {
      enable = true;
    };
    cfg.lldap = {
      enable = true;
    };
  };

  imports = [
    ./pocketid
    ./lldap
  ];
}
