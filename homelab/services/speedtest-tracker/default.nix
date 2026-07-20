{
  config,
  lib,
  ...
}:
let
  service = "speedtest-tracker";
  hl = config.homelab;
  cfg = hl.services.${service};
  stCfg = config.services.speedtest-tracker;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";
    url = lib.mkOption {
      type = lib.types.str;
      default = "speedtest.${hl.baseDomainName}";
    };
    appKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        File containing the Speedtest Tracker APP_KEY, e.g. generated via:
        echo "base64:$(head -c 32 /dev/urandom | base64)" > /path/to/key-file
      '';
    };
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "Speedtest Tracker";
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
      group = "caddy";
      virtualHost = cfg.url;
      settings = {
        APP_KEY_FILE = cfg.appKeyFile;
        APP_URL = "https://${cfg.url}";
        APP_DEBUG = "true";
      };
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        root * ${stCfg.package}/public
        php_fastcgi unix/${config.services.phpfpm.pools.${service}.socket}
        file_server
      '';
    };
  };
}
