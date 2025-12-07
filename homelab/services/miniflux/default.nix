{
  config,
  pkgs,
  lib,
  ...
}: 
let 
  cfg = config.homelab.services.miniflux;
in
{
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

        }
        (lib.filterAttrs (name: _: !(builtins.elem name [
          "enable"
          "adminUsername"
          "adminPasswordFile"
          "adminUsernameFile"
        ])) cfg)
      ];
    };
  };
}
