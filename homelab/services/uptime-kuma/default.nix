{
  config,
  lib,
  ...
}:
let
  service = "uptime-kuma";
  hl = config.homelab;
  cfg = hl.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";
    url = lib.mkOption {
      type = lib.types.str;
      default = "uptime.${hl.baseDomainName}";
    };
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "Uptime Kuma";
    };
    glance.url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "https://${cfg.url}";
      description = "URL to show for this service in the Glance homelab bookmarks";
    };
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3001
      '';
    };
  };
}
