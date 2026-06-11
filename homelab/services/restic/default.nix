{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.restic;
  hl = config.homelab;
in
{
  options.homelab.services.restic = {
    enable = lib.mkEnableOption "Restic backup for homelab data";
    repository = lib.mkOption {
      type = lib.types.str;
      description = "Restic repository URL (e.g. s3:s3.amazonaws.com/bucket, /mnt/backup, sftp:user@host:/path)";
    };
    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the restic repository encryption password";
    };
    # For cloud backends: file with provider creds, e.g.
    #   AWS_ACCESS_KEY_ID=...
    #   AWS_SECRET_ACCESS_KEY=...
    #   B2_ACCOUNT_ID=...  etc.
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "File with cloud backend credentials";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Paths to back up";
      default = [
        "/var/lib"
        hl.mounts.config
      ];
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "03:30";
      description = "systemd OnCalendar schedule for the backup job";
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.homelab = {
      paths = cfg.paths;
      repository = cfg.repository;
      passwordFile = cfg.passwordFile;
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
      initialize = true;
    }
    // lib.optionalAttrs (cfg.environmentFile != null) {
      environmentFile = cfg.environmentFile;
    };

    systemd.services."restic-backups-homelab".serviceConfig.OnFailure = lib.mkIf (
      hl.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
