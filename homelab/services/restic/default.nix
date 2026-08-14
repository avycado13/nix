{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  cfg = hl.services.restic;

  # Services that declared what they need backed up via `data`.
  dataServices = lib.filterAttrs (
    _: svc: lib.isAttrs svc && (svc.enable or false) && (svc.data or null) != null
  ) hl.services;

  # verb: the systemctl subcommand ("stop"/"start"); label: past-continuous
  # form for the log line ("Stopping"/"Starting").
  mkStopCmds =
    units: verb: label:
    lib.concatMapStringsSep "\n" (u: ''
      echo "${label} ${u} for backup..."
      systemctl ${verb} ${u} || echo "WARNING: failed to ${verb} ${u}"
    '') units;

  # Auto-generate a restic backup job from a service's `data` declaration.
  mkBackupJob =
    name: svc:
    let
      d = svc.data;
      hasSqlite = d.sqlite != null;
      hasPostgres = d.postgres != null;
      dumpDir = "/var/backup/restic-${name}";
      stopUnits = if d.stopUnits != [ ] then d.stopUnits else [ name ];

      prepareCommand = lib.concatStringsSep "\n" (
        lib.optional hasSqlite ''
          echo "Checkpointing sqlite WAL for ${name}..."
          ${pkgs.sqlite}/bin/sqlite3 "${d.sqlite}" "PRAGMA wal_checkpoint(TRUNCATE);" || true
        ''
        ++ lib.optional hasPostgres ''
          echo "Dumping PostgreSQL database ${d.postgres} for ${name}..."
          install -d -m 0700 -o postgres -g postgres ${dumpDir}
          ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dump ${d.postgres} > ${dumpDir}/dump.sql
        ''
        ++ lib.optional d.stopForBackup (mkStopCmds stopUnits "stop" "Stopping")
      );

      cleanupCommand = lib.concatStringsSep "\n" (
        lib.optional d.stopForBackup (mkStopCmds stopUnits "start" "Starting")
        ++ lib.optional hasPostgres "rm -rf ${dumpDir}"
      );

      paths =
        (lib.optional hasSqlite (builtins.dirOf d.sqlite)) ++ (lib.optional hasPostgres dumpDir) ++ d.files;
    in
    {
      inherit paths;
      exclude = d.exclude;
      repository = cfg.repository;
      passwordFile = cfg.passwordFile;
      initialize = true;
      # Retention is enforced once for the whole repository by the shared
      # weekly prune below (see its comment for why per-service prune is
      # actively harmful on a repo this small).
      pruneOpts = [ ];
      extraBackupArgs = [
        "--tag service:${name}"
      ]
      ++ lib.optional hasSqlite "--tag type:sqlite"
      ++ lib.optional hasPostgres "--tag type:postgres";
      timerConfig = {
        OnCalendar = cfg.schedule;
        RandomizedDelaySec = "20m";
        Persistent = true;
      };
      backupPrepareCommand = lib.mkIf (prepareCommand != "") prepareCommand;
      backupCleanupCommand = lib.mkIf (cleanupCommand != "") cleanupCommand;
    }
    // lib.optionalAttrs (cfg.environmentFile != null) {
      environmentFile = cfg.environmentFile;
    };
in
{
  options.homelab.services.restic = {
    enable = lib.mkEnableOption "Restic backups for services that declare a `data` option";
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
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "03:30";
      description = "systemd OnCalendar schedule for each service's backup job";
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups = lib.mapAttrs mkBackupJob dataServices;

    systemd.services =
      (lib.mapAttrs' (
        name: _:
        lib.nameValuePair "restic-backups-${name}" {
          unitConfig.OnFailure = lib.mkIf (
            hl.notifications.ntfySecretsFile != null
          ) "notify-failure@%n.service";
        }
      ) dataServices)
      // {
        # ONE weekly prune for the whole repository.
        #
        # Per-service prune (`forget --prune --tag service:X`) only uses the
        # tag to pick which *snapshots to forget* -- the prune that follows
        # still walks and repacks the entire repository. So N services would
        # mean N full-repo repacks per week, which blows through B2's Class B
        # transaction cap fast and can wedge a prune mid-run, leaving an
        # exclusive lock that blocks every backup until someone notices.
        #
        # `--group-by host,tags` applies the retention policy independently
        # to each service's tag group, so per-service retention is preserved
        # exactly, but the repository is only repacked once.
        restic-prune = {
          description = "Weekly restic forget/prune for all services";
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
            # A prune that hangs holds the repo's exclusive lock and blocks
            # every backup until someone notices. Bound it; restic releases
            # its lock on SIGTERM.
            TimeoutStartSec = "6h";
          };
          script = ''
            set -euo pipefail

            restic() {
              ${pkgs.restic}/bin/restic \
                --repo ${lib.escapeShellArg cfg.repository} \
                --password-file ${lib.escapeShellArg cfg.passwordFile} \
                "$@"
            }

            # Clear locks whose owning process is gone (e.g. a prune killed
            # mid-run). This only removes *stale* locks, never a live one.
            restic unlock || true

            restic forget --prune --verbose \
              --group-by host,tags \
              --keep-last 3 --keep-daily 7 --keep-weekly 5 --keep-monthly 12
          '';
          unitConfig.OnFailure = lib.mkIf (
            hl.notifications.ntfySecretsFile != null
          ) "notify-failure@%n.service";
        };
      };

    systemd.timers.restic-prune = {
      description = "Weekly restic prune (Sun)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun *-*-* 05:00:00";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };

    environment.systemPackages = [
      pkgs.restic
      pkgs.sqlite
    ];
  };
}
