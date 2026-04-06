{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.glance;
  hl = config.homelab;
  port = 8085;
in
{
  options.homelab.services.glance = {
    enable = lib.mkEnableOption "Glance homelab dashboard";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain to serve Glance on";
    };
    # Add widgets to the main (full-width) column.
    # See https://github.com/glanceapp/glance/blob/main/docs/configuration.md
    extraWidgets = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Additional widgets for the main column";
      example = lib.literalExpression ''
        [
          {
            type = "rss";
            title = "News";
            feeds = [ { url = "https://lobste.rs/rss"; } ];
          }
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.glance = {
      enable = true;
      settings = {
        server.port = port;
        pages = [
          {
            name = "Home";
            columns = [
              {
                size = "small";
                widgets = [
                  { type = "clock"; }
                  { type = "resources"; }
                ];
              }
              {
                size = "full";
                widgets = cfg.extraWidgets;
              }
            ];
          }
        ];
      };
    };

    services.caddy.virtualHosts."${cfg.domain}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };

    systemd.services.glance.serviceConfig.OnFailure = lib.mkIf (
      hl.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
