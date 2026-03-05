{
  config,
  lib,
  ...
}:
let
  service = "miniflux";
  hl = config.homelab;
  cfg = hl.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "news.avyay.in";
    };
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "Miniflux";
    };
    glance.description = lib.mkOption {
      type = lib.types.str;
      default = "Minimalist and opinionated feed reader";
    };
    adminCredentialsFile = lib.mkOption {
      description = "File with admin credentials";
      type = lib.types.path;
    };
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      default = "client";
    };
  };
  config =
    let
      addr = "127.0.0.1";
      port = 8067;
    in
    lib.mkIf cfg.enable {
      services.${service} = {
        enable = true;
        adminCredentialsFile = cfg.adminCredentialsFile;
        config = {
          BASE_URL = "https://${cfg.url}";
          CREATE_ADMIN = true;
          LISTEN_ADDR = "${addr}:${toString port}";
          OAUTH2_PROVIDER = "oidc";
          OAUTH2_CLIENT_ID = "miniflux";
          OAUTH2_REDIRECT_URL = "https://${cfg.url}/oauth2/oidc/callback";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${hl.services.indiko.url}/.well-known/openid-configuration";
          OAUTH2_USER_CREATION = "1";
          DISABLE_LOCAL_AUTH = "true";
        };
      };
      services.caddy.virtualHosts."${cfg.url}" = {
        useACMEHost = "avyay.in";
        extraConfig = ''
          reverse_proxy http://${addr}:${toString port}
        '';
      };
    };
}
