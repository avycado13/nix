{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.services."git-pr";
  name = "git-pr";
  package = pkgs.git-pr;
in
{
  options.homelab.services."git-pr" = {
    enable = lib.mkEnableOption "picosh/git-pr patch request service";

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Domain to serve git-pr web UI on";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "HTTP port for git-pr web UI";
    };

    sshPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = 2222;
      description = "SSH port for git-pr endpoint";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/git-pr";
      description = "Directory to store git-pr state and config";
    };

    configDir = lib.mkOption {
      type = lib.types.path;
      default = cfg.dataDir;
      description = "Directory containing git-pr configuration";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.configDir}/git-pr.toml";
      description = "Path to git-pr.toml";
    };

    caddy.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Caddy reverse proxy for git-pr web UI";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${name} = {
      isSystemUser = true;
      group = name;
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.${name} = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${name} ${name} -"
    ];

    systemd.services.${name} = {
      description = "git-pr";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ package ];
      preStart = ''
        mkdir -p ${cfg.configDir}
        if [ ! -f ${cfg.configFile} ]; then
          cat > ${cfg.configFile} <<EOF
url = "${if cfg.domain != null then cfg.domain else "localhost"}"
data_dir = "${cfg.dataDir}"
EOF
        fi
        chown -R ${name}:${name} ${cfg.dataDir}
      '';
      serviceConfig = {
        Type = "exec";
        User = name;
        Group = name;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${package}/bin/git-pr --config ${cfg.configFile}";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
        Environment = [
          "GITPR_WEB_PORT=${toString cfg.port}"
        ]
        ++ lib.optional (cfg.sshPort != null) "GITPR_SSH_PORT=${toString cfg.sshPort}";
      };
    };

    networking.firewall.allowedTCPPorts =
      [ cfg.port ]
      ++ lib.optional (cfg.sshPort != null) cfg.sshPort;

    services.caddy.virtualHosts = lib.mkIf (cfg.caddy.enable && cfg.domain != null) {
      "${cfg.domain}" = {
        extraConfig = ''
          reverse_proxy localhost:${toString cfg.port}
        '';
      };
    };
  };
}
