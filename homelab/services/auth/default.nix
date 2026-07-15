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
    homelab.services.indiko.enable = true;
  };

  imports = [
    ./indiko
  ];
}
