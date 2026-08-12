{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = "irc";
  hl = config.homelab;
  cfg = hl.services.${service};
  certDir = config.security.acme.certs.${hl.baseDomainName}.directory;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable soju IRC bouncer and eventually gamja";
    url = lib.mkOption {
      type = lib.types.str;
      default = "irc.${hl.baseDomainName}";
      description = "Hostname soju identifies as and serves TLS for";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 6697;
      description = "Port soju listens on for gamja and websocket connections";
    };
    ircsPort = lib.mkOption {
      type = lib.types.port;
      default = 6697;
      description = "Port soju listens on for IRC-over-TLS connections";
    };
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "Soju";
    };
    glance.url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = cfg.url;
      description = "Gamja web ui";
    };
  };

  config = lib.mkIf cfg.enable {
    services.soju = {
      enable = true;
      hostName = cfg.url;
      listen = [
        "ircs://:${toString cfg.ircsPort}"
        "ws+insecure://:${toString cfg.port}"
      ];
      tlsCertificate = "${certDir}/fullchain.pem";
      tlsCertificateKey = "${certDir}/key.pem";
    };

    # soju runs with a static user (not DynamicUser) so it can be added to
    # the ACME cert group and read the shared wildcard cert/key.
    users.users.soju = {
      isSystemUser = true;
      group = "soju";
      extraGroups = [ config.services.caddy.group ];
    };
    users.groups.soju = { };
    systemd.services.soju.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "soju";
      Group = "soju";
    };

    security.acme.certs.${hl.baseDomainName}.reloadServices = [ "soju.service" ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        root * ${pkgs.compressDrvWeb pkgs.gamja { }}
        file_server browse {
            precompressed br gzip
        }
        reverse_proxy /socker http://127.0.0.1:${toString cfg.port}
      '';
    };

    systemd.services.soju.serviceConfig.OnFailure = lib.mkIf (
      hl.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
