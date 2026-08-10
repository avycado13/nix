{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.calibre-web;
  hl = config.homelab;
  port = 8083;
in
{
  options.homelab.services.calibre-web = {
    enable = lib.mkEnableOption "Calibre-Web ebook library server";
    url = lib.mkOption {
      type = lib.types.str;
      default = "books.${hl.baseDomainName}";
      description = "Domain to serve Calibre-Web on";
    };
    libraryPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/calibre-web/library";
      description = ''
        Path to the Calibre library directory (must contain metadata.db;
        create one with `calibredb` before first start if starting fresh).
      '';
    };
    enableBookUploading = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow books to be uploaded via the Calibre-Web UI";
    };
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "Calibre-Web";
    };
    glance.url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "https://${cfg.url}";
      description = "URL to show for this service in the Glance homelab bookmarks";
    };
  };

  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      listen = {
        ip = "127.0.0.1";
        inherit port;
      };
      options = {
        calibreLibrary = cfg.libraryPath;
        enableBookUploading = cfg.enableBookUploading;
        enableBookConversion = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.libraryPath} 0750 calibre-web calibre-web -"
    ];

    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };

    systemd.services.calibre-web.unitConfig.OnFailure = lib.mkIf (
      hl.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
