{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = "indiko";
  cfg = config.homelab.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Indiko authentication service";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain to serve indiko on";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for indiko to listen on";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/${service}";
      description = "Directory to store indiko's app checkout and data";
    };

    repository = lib.mkOption {
      type = lib.types.str;
      description = "Git repository to deploy indiko from";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch to deploy";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Git pull the latest revision of branch on every service restart";
    };

    secretsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "EnvironmentFile with indiko secrets";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${service} = { };
    users.users.${service} = {
      isSystemUser = true;
      group = service;
      home = cfg.dataDir;
      createHome = true;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${service} ${service} -"
    ];

    systemd.services.${service} = {
      description = "Indiko authentication service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [
        pkgs.bun
        pkgs.git
      ];

      preStart = ''
        set -e
        if [ ! -d ${cfg.dataDir}/app/.git ]; then
          ${pkgs.git}/bin/git clone -b ${cfg.branch} ${cfg.repository} ${cfg.dataDir}/app
        fi
        cd ${cfg.dataDir}/app
        ${lib.optionalString cfg.autoUpdate ''
          ${pkgs.git}/bin/git fetch origin
          ${pkgs.git}/bin/git reset --hard origin/${cfg.branch}
        ''}
        ${pkgs.bun}/bin/bun install
      '';

      script = ''
        cd ${cfg.dataDir}/app
        exec ${pkgs.bun}/bin/bun run start
      '';

      serviceConfig = {
        Type = "exec";
        User = service;
        Group = service;
        WorkingDirectory = "${cfg.dataDir}/app";
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStartSec = "120s";
        EnvironmentFile = lib.mkIf (cfg.secretsFile != null) cfg.secretsFile;
        Environment = [ "PORT=${toString cfg.port}" ];

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
        PrivateTmp = true;
      };
    };

    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = ''
        reverse_proxy localhost:${toString cfg.port}
         header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; script-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self';"
        }
      '';
    };
  };
}
