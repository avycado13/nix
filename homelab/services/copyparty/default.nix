let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "copyparty";
  description = "Portable file server with accelerated resumable uploads";
  defaultPort = 3923;
  runtime = "container";
  defaultImage = "ghcr.io/9001/copyparty:latest";

  extraOptions =
    { lib, ... }:
    {
      volumesPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to volumes configuration (host path for mounting volumes).";
      };

      uploadsPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path for file uploads (host path).";
      };

      accounts = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "User accounts configuration (format: username:password:permissions).";
      };

      enableAuth = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable authentication.";
      };
    };

  extraConfig =
    cfg:
    { config, lib, ... }:
    {
      homelab.services.copyparty.container = {
        volumes = lib.optionals (cfg.volumesPath != "") [ "${cfg.volumesPath}:/data" ]
          ++ lib.optionals (cfg.uploadsPath != "") [ "${cfg.uploadsPath}:/uploads" ]
          ++ [ "${cfg.dataDir}:/config" ];

        cmd = [ ]
          ++ lib.optionals (cfg.enableAuth && cfg.accounts != "") [ "-a" cfg.accounts ]
          ++ lib.optionals (cfg.volumesPath != "") [ "/data" ]
          ++ lib.optionals (cfg.uploadsPath != "") [ "/uploads" ];
      };

      homelab.services.copyparty.environment = {
        TZ = config.homelab.timeZone or "UTC";
      };
    };
}
