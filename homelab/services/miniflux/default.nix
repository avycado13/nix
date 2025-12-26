{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homelab.services.miniflux;
in {
  options.homelab.services.miniflux = {
    enable = lib.mkEnableOption "Miniflux RSS Feed Reader Service";

    # Admin Configuration
    adminPasswordFile = lib.mkOption {
      default = "";
      type = lib.types.str;
      description = ''
        Path to a secret key exposed as a file, it should contain $ADMIN_PASSWORD value.
        Default is empty.
      '';
    };
    adminUsername = lib.mkOption {
      default = "";
      type = lib.types.str;
      description = ''
        Admin user login, it's used only if CREATE_ADMIN is enabled.
        Default is empty.
      '';
    };
    adminUsernameFile = lib.mkOption {
      default = "";
      type = lib.types.str;
      description = ''
        Path to a secret key exposed as a file, it should contain $ADMIN_USERNAME value.
        Default is empty.
      '';
    };
    listenAddr = lib.mkOption {
      default = "";
      type = lib.types.str;
      description = ''
        Address and port on which Miniflux will listen (e.g., ":8080").
        Default is empty, which lets Miniflux use its default settings.
      '';
    };
    databaseUrl = lib.mkOption {
      default = "postgres://miniflux:miniflux@localhost:5432/miniflux?sslmode=disable&connect_timeout=10";
      type = lib.types.str;
      description = ''
        Database connection URL.
        Default is "postgres://miniflux:miniflux@localhost:5432/miniflux?sslmode=disable&connect_timeout=10".
      '';
    };
    config = lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.miniflux = {
        enable = true;
        image = {
          repository = "miniflux/miniflux";
          tag = "latest";
        };
        environment = lib.mkMerge [
          {
            inherit (cfg) listenAddr;
            ADMIN_USERNAME = cfg.adminUsername;
            ADMIN_PASSWORD_FILE = cfg.adminPasswordFile;
            ADMIN_USERNAME_FILE = cfg.adminUsernameFile;
            DATABASE_URL = cfg.databaseUrl;
          }
          (lib.filterAttrs (name: _:
            !(builtins.elem name [
              "enable"
              "adminUsername"
              "adminPasswordFile"
              "adminUsernameFile"
              "listenAddr"
              "databaseUrl"
            ]))
          cfg)
        ];
      };
    };
  };
}
