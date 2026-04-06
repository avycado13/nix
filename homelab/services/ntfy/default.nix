{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.ntfy;
  hl = config.homelab;
in
{
  options.homelab.services.ntfy = {
    enable = lib.mkEnableOption "ntfy push notification server";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain to serve ntfy on (e.g. ntfy.example.com)";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 2586;
    };
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://${cfg.domain}";
        listen-http = ":${toString cfg.port}";
        behind-proxy = true;
        cache-file = "/var/lib/ntfy-sh/cache.db";
        # Require authentication — create users with `ntfy user add`
        auth-default-access = "deny-all";
      };
    };

    services.caddy.virtualHosts."${cfg.domain}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString cfg.port}
      '';
    };

    systemd.services.ntfy-sh.serviceConfig.OnFailure = lib.mkIf (
      hl.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
