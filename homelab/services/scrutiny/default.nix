{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.scrutiny;
  hl = config.homelab;
  port = 8086;
in
{
  options.homelab.services.scrutiny = {
    enable = lib.mkEnableOption "Scrutiny SMART disk health monitoring";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain to serve Scrutiny on";
    };
    # Shoutrrr notification URLs — see https://containrrr.dev/shoutrrr/
    # For self-hosted ntfy: "ntfy://user:pass@ntfy.example.com/topic"
    # For ntfy.sh (no auth): "ntfy://ntfy.sh/topic"
    notifyUrls = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Shoutrrr notification URLs for disk failure alerts";
      example = [ "ntfy://ntfy.example.com/disk-alerts" ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.scrutiny = {
      enable = true;
      # Run the collector on this host to gather SMART data
      collector.enable = true;
      settings = {
        web.listen.port = port;
        notify.urls = cfg.notifyUrls;
      };
    };

    services.caddy.virtualHosts."${cfg.domain}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };
  };
}
