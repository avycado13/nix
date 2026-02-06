let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "upsnap";
  description = "UPSnap Device Monitoring Service";
  defaultPort = 5000;
  runtime = "container";
  defaultImage = "ghcr.io/seriousm4x/upsnap:5";

  extraOptions =
    { lib, ... }:
    {
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
        description = "Whether to run ping as privileged.";
      };

      listenAddr = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0:5000";
        description = "Address and port UPSnap listens on inside the container.";
      };
    };

  extraConfig =
    cfg:
    { config, lib, ... }:
    {
      homelab.services.upsnap.container = {
        volumes = [ "${cfg.dataDir}:/app/pb_data" ];
        entrypoint = "/bin/sh";
        cmd = [
          "-c"
          "./upsnap serve --http ${cfg.listenAddr}"
        ];
      };

      homelab.services.upsnap.environment = {
        TZ = config.homelab.timeZone or "UTC";
        UPSNAP_INTERVAL = cfg.interval;
        UPSNAP_SCAN_RANGE = cfg.scanRange;
        UPSNAP_SCAN_TIMEOUT = cfg.scanTimeout;
        UPSNAP_PING_PRIVILEGED = lib.boolToString cfg.pingPrivileged;
      };
    };
}
