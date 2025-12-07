{ config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.services.upsnap;
in
{
  options.homelab.services.upsnap = {
    enable = lib.mkEnableOption "UPSnap Device Monitoring Service";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to UPSnap data directory on the host.";
    };

    tz = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Timezone for the container (e.g., Europe/Berlin).";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Cron-like interval for pinging devices.";
    };

    scanRange = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Network scan range for device discovery.";
    };

    scanTimeout = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Scan timeout (e.g., 500ms).";
    };

    pingPrivileged = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run ping as privileged (true/false).";
    };

    websiteTitle = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Custom website title.";
    };

    listenAddr = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:5000";
      description = "Address and port UPSnap listens on inside the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.upsnap = {
      enable = true;
      image = {
        repository = "ghcr.io/seriousm4x/upsnap";
        tag = "5";
      };

      # Volumes
      volumes = [
        "${cfg.dataDir}:/app/pb_data"
      ];

      # Environment variables
      environment = lib.mkMerge [
        {
          TZ = cfg.tz;
          UPSNAP_INTERVAL = cfg.interval;
          UPSNAP_SCAN_RANGE = cfg.scanRange;
          UPSNAP_SCAN_TIMEOUT = cfg.scanTimeout;
          UPSNAP_PING_PRIVILEGED = lib.toString cfg.pingPrivileged;
          UPSNAP_WEBSITE_TITLE = cfg.websiteTitle;
        }
      ];

      # Optional entrypoint override to specify listen address
      entrypoint = [ "/bin/sh" "-c" ''./upsnap serve --http ${cfg.listenAddr}'' ];
    };
  };
}