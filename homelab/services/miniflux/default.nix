let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "miniflux";
  description = "Miniflux RSS Feed Reader Service";
  defaultPort = 8080;
  runtime = "container";
  defaultImage = "miniflux/miniflux:latest";

  extraOptions =
    { lib, ... }:
    {
      adminPasswordFile = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to a secret file containing ADMIN_PASSWORD value.";
      };

      adminUsername = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Admin user login for CREATE_ADMIN.";
      };

      adminUsernameFile = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to a secret file containing ADMIN_USERNAME value.";
      };

      listenAddr = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Address and port for Miniflux to listen on (e.g., ':8080').";
      };

      databaseUrl = lib.mkOption {
        type = lib.types.str;
        default = "postgres://miniflux:miniflux@localhost:5432/miniflux?sslmode=disable&connect_timeout=10";
        description = "Database connection URL.";
      };
    };

  extraConfig = cfg: {
    homelab.services.miniflux.environment = {
      LISTEN_ADDR = cfg.listenAddr;
      ADMIN_USERNAME = cfg.adminUsername;
      ADMIN_PASSWORD_FILE = cfg.adminPasswordFile;
      ADMIN_USERNAME_FILE = cfg.adminUsernameFile;
      DATABASE_URL = cfg.databaseUrl;
    };
  };
}
