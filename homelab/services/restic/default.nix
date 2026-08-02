{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.restic;
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
      ];
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "03:30";
      description = "systemd OnCalendar schedule for the backup job";
    };
    postgresBackup = lib.mkOption {
      type = lib.types.bool;
      default = config.services.postgresql.enable;
      defaultText = lib.literalExpression "config.services.postgresql.enable";
      description = ''
        Dump all PostgreSQL databases with pg_dumpall before each backup run
        and back up the dump instead of PostgreSQL's raw data directory,
        which restic can otherwise capture mid-write and produce a
        restorable-but-inconsistent copy of.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.homelab = {
      paths = cfg.paths ++ lib.optional cfg.postgresBackup "/var/backup/postgresql";
      exclude = lib.optional cfg.postgresBackup "/var/lib/postgresql";
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
      backupPrepareCommand = lib.mkIf cfg.postgresBackup ''
        install -d -m 0700 /var/backup/postgresql
        ${config.services.postgresql.package}/bin/pg_dumpall --clean --if-exists -f /var/backup/postgresql/dump.sql
      '';
      backupCleanupCommand = lib.mkIf cfg.postgresBackup ''
        rm -rf /var/backup/postgresql
      '';
    }
    // lib.optionalAttrs (cfg.environmentFile != null) {
      environmentFile = cfg.environmentFile;
    };

    systemd.services."restic-backups-homelab".serviceConfig.OnFailure = lib.mkIf (
      config.homelab.notifications.ntfySecretsFile != null
    ) "notify-failure@%n.service";
  };
}
