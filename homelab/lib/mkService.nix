# mkService - Base service factory for homelab services
#
# Creates a standardized NixOS service module with:
# - Common options (domain, port, dataDir, secrets, etc.)
# - Systemd service with git-based deployment
# - OCI container support
# - Caddy reverse proxy configuration
# - Automatic backup for SQLite and PostgreSQL
# - Port conflict detection
# - Dedicated user per service
#
# Usage in a service module:
#   let
#     mkService = import ../../lib/mkService.nix;
#   in
#   mkService {
#     name = "myapp";
#     defaultPort = 3000;
#     runtime = "bun";
#     extraOptions = { ... };
#     extraConfig = cfg: { ... };
#   }

{
  # Service identity
  name,
  description ? "${name} service",
  defaultPort ? 3000,

  # Runtime configuration
  # "bun" | "node" | "systemd" | "container" | "nixos"
  runtime ? "bun",
  entryPoint ? "src/index.ts",
  # Override the start command entirely
  startCommand ? null,

  # Container configuration (when runtime = "container")
  defaultImage ? null,

  # NixOS service configuration (when runtime = "nixos")
  # Maps to an existing services.* option
  nixosService ? null,

  # Additional options specific to this service
  extraOptions ? { },

  # Additional config when service is enabled
  # Receives cfg (the service config) as argument
  extraConfig ? _cfg: { },
}:

# Return a proper NixOS module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.services.${name};

  # Generate start command based on runtime
  defaultStartCommand =
    {
      bun = "${pkgs.unstable.bun}/bin/bun run ${entryPoint}";
      node = "${pkgs.nodejs_22}/bin/node ${entryPoint}";
      systemd = null;
      container = null;
      nixos = null;
    }
    .${runtime} or null;

  finalStartCommand = if startCommand != null then startCommand else defaultStartCommand;

  # Runtime-specific packages
  runtimePackages =
    {
      bun = [
        pkgs.unstable.bun
        pkgs.git
        pkgs.openssh
      ];
      node = [
        pkgs.nodejs_22
        pkgs.git
        pkgs.openssh
      ];
      systemd = [
        pkgs.git
        pkgs.openssh
      ];
      container = [ ];
      nixos = [ ];
    }
    .${runtime} or [ ];

  # Working directory
  workDir =
    if cfg.workingDirectory != null then
      cfg.workingDirectory
    else if cfg.deploy.enable && cfg.deploy.repository != null then
      "${cfg.dataDir}/app"
    else
      cfg.dataDir;

  # Backup script
  backupScript = pkgs.writeShellScript "${name}-backup" ''
    set -euo pipefail
    BACKUP_DIR="${cfg.backup.backupDir}"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SERVICE_STOPPED=false

    mkdir -p "$BACKUP_DIR"

    cleanup() {
      if [ "$SERVICE_STOPPED" = true ]; then
        echo "Restarting ${name} service..."
        systemctl start ${name}.service || true
      fi
    }
    trap cleanup EXIT

    ${lib.optionalString (cfg.backup.sqlite.enable && cfg.backup.sqlite.databases != [ ]) ''
      echo "Backing up SQLite databases..."

      ${lib.optionalString cfg.backup.sqlite.stopService ''
        echo "Stopping ${name} service for consistent backup..."
        systemctl stop ${name}.service
        SERVICE_STOPPED=true
      ''}

      ${lib.concatMapStringsSep "\n" (db: ''
        DB_PATH="${cfg.dataDir}/${db}"
        DB_NAME=$(basename "${db}" .db)
        if [ -f "$DB_PATH" ]; then
          # Checkpoint WAL if exists
          if [ -f "$DB_PATH-wal" ]; then
            ${pkgs.sqlite}/bin/sqlite3 "$DB_PATH" "PRAGMA wal_checkpoint(TRUNCATE);" || true
          fi
          ${pkgs.sqlite}/bin/sqlite3 "$DB_PATH" ".backup '$BACKUP_DIR/$DB_NAME.$TIMESTAMP.sqlite'"
          echo "Backed up $DB_PATH"
        else
          echo "Warning: SQLite database $DB_PATH not found"
        fi
      '') cfg.backup.sqlite.databases}
    ''}

    ${lib.optionalString (cfg.backup.postgres.enable && cfg.backup.postgres.databases != [ ]) ''
      echo "Backing up PostgreSQL databases..."
      ${lib.concatMapStringsSep "\n" (db: ''
        ${pkgs.postgresql}/bin/pg_dump -U ${cfg.backup.postgres.user} -h localhost ${db} \
          | ${pkgs.gzip}/bin/gzip > "$BACKUP_DIR/${db}.$TIMESTAMP.sql.gz"
        echo "Backed up PostgreSQL database ${db}"
      '') cfg.backup.postgres.databases}
    ''}

    ${lib.optionalString (cfg.backup.files != [ ]) ''
      echo "Backing up additional files..."
      ${lib.concatMapStringsSep "\n" (path: ''
        if [ -e "${path}" ]; then
          BASENAME=$(basename "${path}")
          ${pkgs.gnutar}/bin/tar -czf "$BACKUP_DIR/$BASENAME.$TIMESTAMP.tar.gz" \
            ${lib.concatMapStringsSep " " (e: "--exclude='${e}'") cfg.backup.exclude} \
            -C "$(dirname "${path}")" "$BASENAME"
          echo "Backed up ${path}"
        fi
      '') cfg.backup.files}
    ''}

    # Cleanup old backups
    echo "Cleaning up backups older than ${toString cfg.backup.retentionDays} days..."
    find "$BACKUP_DIR" -type f -mtime +${toString cfg.backup.retentionDays} -delete

    echo "Backup completed successfully"
  '';

in
{
  options.homelab.services.${name} = {
    enable = lib.mkEnableOption description;

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Domain to serve ${name} on";
    };

    port = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = defaultPort;
      description = "Port to run ${name} on";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/${name}";
      description = "Directory to store ${name} data";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Working directory (defaults to dataDir or dataDir/app if using git deploy)";
    };

    secretsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to agenix secrets file";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to add to service PATH";
    };

    # Git-based deployment
    deploy = {
      enable = lib.mkEnableOption "Git-based deployment" // {
        default = true;
      };

      repository = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git repository URL for auto-deployment";
      };

      autoUpdate = lib.mkEnableOption "Automatically git pull on service restart";

      branch = lib.mkOption {
        type = lib.types.str;
        default = "main";
        description = "Git branch to deploy";
      };
    };

    # Restart configuration
    restart = {
      policy = lib.mkOption {
        type = lib.types.enum [
          "no"
          "on-success"
          "on-failure"
          "on-abnormal"
          "on-watchdog"
          "on-abort"
          "always"
        ];
        default = "on-failure";
        description = "Restart policy for the service";
      };

      delaySec = lib.mkOption {
        type = lib.types.str;
        default = "10s";
        description = "Delay before restarting";
      };

      maxRetries = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Maximum restart attempts within the interval";
      };

      intervalSec = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "Interval (seconds) for counting restart attempts";
      };
    };

    # User configuration
    user = {
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "User name (defaults to service name)";
      };

      createUser = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create a dedicated user for this service";
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "services" ];
        description = "Additional groups for the service user";
      };

      allowSudoRestart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Allow service user to restart their own service via sudo";
      };
    };

    # Caddy reverse proxy
    caddy = {
      enable = lib.mkEnableOption "Caddy reverse proxy" // {
        default = true;
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Additional Caddy configuration";
      };

      tls = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TLS";
      };

      rateLimit = {
        enable = lib.mkEnableOption "Rate limiting";

        events = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Number of requests allowed per window";
        };

        window = lib.mkOption {
          type = lib.types.str;
          default = "1m";
          description = "Time window for rate limiting";
        };
      };

      headers = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Headers to add to proxied requests";
      };
    };

    # Backup configuration
    backup = {
      enable = lib.mkEnableOption "Enable backups for this service";

      sqlite = {
        enable = lib.mkEnableOption "Enable SQLite backup";

        databases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of SQLite database paths relative to dataDir";
          example = [
            "data.db"
            "app/database.sqlite"
          ];
        };

        stopService = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Stop service during backup for consistency";
        };
      };

      postgres = {
        enable = lib.mkEnableOption "Enable PostgreSQL backup";

        databases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of PostgreSQL database names to backup";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "PostgreSQL user for backups";
        };
      };

      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional file/directory paths to backup";
        example = [ "/var/lib/myapp/uploads" ];
      };

      exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "*.log"
          "node_modules"
          ".git"
          "cache"
          "tmp"
        ];
        description = "Glob patterns to exclude from file backups";
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "Backup schedule (systemd calendar format)";
      };

      retentionDays = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of days to retain backups";
      };

      backupDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/backup/${name}";
        description = "Directory to store backups";
      };
    };

    # Container configuration (for runtime = "container")
    container = {
      image = lib.mkOption {
        type = lib.types.str;
        default = defaultImage;
        description = "Container image (e.g., 'nginx:latest')";
      };

      volumes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Volume mounts (host:container format)";
      };

      ports = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional port mappings (host:container format)";
      };

      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra options for the container runtime";
      };

      cmd = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Command to run in the container";
      };

      entrypoint = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Entrypoint for the container";
      };

      dependsOn = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Containers this service depends on";
      };

      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "User to run container as (uid:gid)";
      };
    };

    # NixOS service passthrough (for runtime = "nixos")
    nixos = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Configuration to pass to the underlying NixOS service.
        For example, if nixosService = "immich", this becomes services.immich settings.
      '';
      example = lib.literalExpression ''
        {
          enable = true;
          mediaLocation = "/var/lib/immich";
          machine-learning.enable = true;
        }
      '';
    };

    # Systemd overrides
    serviceConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional systemd service configuration";
    };

    after = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional systemd units this service should start after";
    };

    requires = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Systemd units this service requires";
    };
  }
  // extraOptions;

  config =
    let
      userName = if cfg.user.name != null then cfg.user.name else name;
    in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        # Port conflict detection
        {
          assertions =
            let
              allServices = lib.filterAttrs (_n: v: v.enable or false) (config.homelab.services or { });
              portsInUse = lib.mapAttrsToList (serviceName: serviceCfg: {
                inherit serviceName;
                port = serviceCfg.port or null;
              }) allServices;
              portsWithValues = lib.filter (p: p.port != null) portsInUse;
              conflicts = lib.filter (p: p.port == cfg.port && p.serviceName != name) portsWithValues;
            in
            [
              {
                assertion = cfg.port == null || conflicts == [ ];
                message = ''
                  Port conflict detected for ${name}!
                  Port ${toString cfg.port} is already used by: ${
                    lib.concatMapStringsSep ", " (c: c.serviceName) conflicts
                  }

                  Ports currently in use:
                  ${lib.concatMapStringsSep "\n  " (p: "${p.serviceName}: ${toString p.port}") portsWithValues}
                '';
              }
            ];
        }

        # User and group creation
        (lib.mkIf cfg.user.createUser {
          users.groups.services = { };
          users.groups.${userName} = { };

          users.users.${userName} = {
            isSystemUser = true;
            group = userName;
            extraGroups = cfg.user.extraGroups;
            home = cfg.dataDir;
            createHome = true;
            shell = pkgs.bash;
          };
        })

        # Sudo rules for service restart
        (lib.mkIf (cfg.user.createUser && cfg.user.allowSudoRestart) {
          security.sudo.extraRules = [
            {
              users = [ userName ];
              commands = [
                {
                  command = "/run/current-system/sw/bin/systemctl restart ${name}.service";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];
        })

        # Systemd service (for non-container runtimes)
        (lib.mkIf (runtime != "container") {
          systemd.services.${name} = {
            inherit description;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ] ++ cfg.after ++ cfg.requires;
            requires = cfg.requires;
            path = runtimePackages ++ cfg.packages;

            preStart =
              lib.optionalString (cfg.deploy.enable && cfg.deploy.repository != null) ''
                set -e
                if [ ! -d ${cfg.dataDir}/app/.git ]; then
                  ${pkgs.git}/bin/git clone -b ${cfg.deploy.branch} ${cfg.deploy.repository} ${cfg.dataDir}/app
                fi
                cd ${cfg.dataDir}/app
              ''
              + lib.optionalString (cfg.deploy.enable && cfg.deploy.autoUpdate) ''
                ${pkgs.git}/bin/git fetch origin || true
                ${pkgs.git}/bin/git reset --hard origin/${cfg.deploy.branch} || true
              ''
              + lib.optionalString (runtime == "bun") ''

                if [ -f package.json ]; then
                  echo "Installing dependencies with bun..."
                  ${pkgs.unstable.bun}/bin/bun install || ${pkgs.unstable.bun}/bin/bun install
                fi
              ''
              + lib.optionalString (runtime == "node") ''

                if [ -f package.json ]; then
                  echo "Installing dependencies with npm..."
                  ${pkgs.nodejs_22}/bin/npm ci --production || ${pkgs.nodejs_22}/bin/npm ci --production
                fi
              '';

            script = lib.mkIf (finalStartCommand != null) "exec ${finalStartCommand}";

            serviceConfig = {
              Type = "exec";
              User = userName;
              Group = userName;
              WorkingDirectory = workDir;
              Restart = cfg.restart.policy;
              RestartSec = cfg.restart.delaySec;
              StartLimitBurst = cfg.restart.maxRetries;
              StartLimitIntervalSec = cfg.restart.intervalSec;
              TimeoutStartSec = "120s";

              # Security hardening
              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadWritePaths = [ cfg.dataDir ] ++ (lib.optional cfg.backup.enable cfg.backup.backupDir);
              PrivateTmp = true;

              Environment = [
                "NODE_ENV=production"
              ]
              ++ lib.optional (cfg.port != null) "PORT=${toString cfg.port}";
            }
            // lib.optionalAttrs (cfg.secretsFile != null) {
              EnvironmentFile = cfg.secretsFile;
            }
            // lib.optionalAttrs (cfg.environment != { }) {
              Environment = [
                "NODE_ENV=production"
              ]
              ++ lib.optional (cfg.port != null) "PORT=${toString cfg.port}"
              ++ lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment;
            }
            // cfg.serviceConfig;

            serviceConfig.ExecStartPre = [
              "!${pkgs.writeShellScript "${name}-setup" ''
                mkdir -p ${cfg.dataDir}/app ${cfg.dataDir}/data
                chown -R ${userName}:${userName} ${cfg.dataDir}
                chmod -R u+rwX,g+rX ${cfg.dataDir}
              ''}"
            ];
          };

          # Ensure directories exist
          systemd.tmpfiles.rules = [
            "d ${cfg.dataDir} 0755 ${userName} ${userName} -"
            "d ${cfg.dataDir}/app 0755 ${userName} ${userName} -"
            "d ${cfg.dataDir}/data 0755 ${userName} ${userName} -"
          ];
        })

        # OCI container (for runtime = "container")
        (lib.mkIf (runtime == "container") {
          virtualisation.oci-containers.containers.${name} = {
            image = cfg.container.image;
            volumes = [ "${cfg.dataDir}:/data" ] ++ cfg.container.volumes;
            ports =
              (lib.optional (cfg.port != null) "${toString cfg.port}:${toString cfg.port}")
              ++ cfg.container.ports;
            environment = {
              TZ = config.homelab.timeZone or "UTC";
            }
            // lib.optionalAttrs (cfg.port != null) {
              PORT = toString cfg.port;
            }
            // cfg.environment;
            extraOptions = [
              "--name=${name}"
            ]
            ++ lib.optional (cfg.container.user != null) "--user=${cfg.container.user}"
            ++ cfg.container.extraOptions;
            cmd = lib.optionals (cfg.container.cmd != [ ]) cfg.container.cmd;
            entrypoint = cfg.container.entrypoint;
            dependsOn = cfg.container.dependsOn;
            autoStart = true;
          };

          systemd.tmpfiles.rules = [
            "d ${cfg.dataDir} 0755 ${userName} ${userName} -"
          ];
        })

        # NixOS service passthrough (for runtime = "nixos")
        (lib.mkIf (runtime == "nixos" && nixosService != null) {
          services.${nixosService} = {
            enable = true;
          }
          // cfg.nixos;

          systemd.tmpfiles.rules = [
            "d ${cfg.dataDir} 0755 ${userName} ${userName} -"
          ];
        })

        # Caddy reverse proxy
        (lib.mkIf (cfg.caddy.enable && cfg.domain != null && cfg.port != null) {
          services.caddy.virtualHosts.${cfg.domain} = {
            extraConfig = ''
              ${lib.optionalString cfg.caddy.tls ''
                tls {
                  dns cloudflare {env.CLOUDFLARE_API_TOKEN}
                }
              ''}

              ${lib.optionalString cfg.caddy.rateLimit.enable ''
                rate_limit {
                  zone ${name}_limit {
                    key {http.request.remote_ip}
                    events ${toString cfg.caddy.rateLimit.events}
                    window ${cfg.caddy.rateLimit.window}
                  }
                }
              ''}

              ${cfg.caddy.extraConfig}

              reverse_proxy localhost:${toString cfg.port} {
                ${lib.concatStringsSep "\n  " (
                  lib.mapAttrsToList (k: v: "header_up ${k} \"${v}\"") cfg.caddy.headers
                )}
              }
            '';
          };
        })

        # Backup service and timer
        (lib.mkIf cfg.backup.enable {
          systemd.services."${name}-backup" = {
            description = "Backup service for ${name}";
            after = [ "${name}.service" ];

            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = "${backupScript}";
            };
          };

          systemd.timers."${name}-backup" = {
            description = "Timer for ${name} backups";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = cfg.backup.schedule;
              Persistent = true;
              RandomizedDelaySec = "5m";
            };
          };

          systemd.tmpfiles.rules = [
            "d ${cfg.backup.backupDir} 0750 ${userName} ${userName} -"
          ];
        })

        # PostgreSQL user/database setup
        (lib.mkIf (cfg.backup.postgres.enable && cfg.backup.postgres.databases != [ ]) {
          services.postgresql = {
            ensureDatabases = cfg.backup.postgres.databases;
            ensureUsers = [
              {
                name = cfg.backup.postgres.user;
                ensureDBOwnership = true;
              }
            ];
          };
        })

        # Extra config from the service module
        (extraConfig cfg)
      ]
    );
}
