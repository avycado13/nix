{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.healthchecks;
  hl = config.homelab;
  port = 8001;
in
{
  options.homelab.services.healthchecks = {
    enable = lib.mkEnableOption "Healthchecks cron/timer monitor";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain to serve Healthchecks on";
    };
    # agenix secret file containing: SECRET_KEY=<django-secret>
    # Optionally also: DEFAULT_FROM_EMAIL=, EMAIL_HOST=, etc.
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "File with SECRET_KEY= (and optional email settings)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.healthchecks = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = port;
      settings = {
        ALLOWED_HOSTS = [
          cfg.domain
          "localhost"
        ];
        # Disable public signups — invite users manually via admin
        REGISTRATION_OPEN = false;
        DEBUG = false;
      };
    };

    # Inject SECRET_KEY from agenix secret without putting it in the store
    systemd.services.healthchecks.serviceConfig = {
      EnvironmentFile = cfg.secretsFile;
      OnFailure = lib.mkIf (hl.notifications.ntfySecretsFile != null) "notify-failure@%n.service";
    };

    services.caddy.virtualHosts."${cfg.domain}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };
  };
}
