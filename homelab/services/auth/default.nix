{
  config,
  lib,
  ...
}:
{
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
