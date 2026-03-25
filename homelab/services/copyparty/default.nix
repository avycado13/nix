{
  config,
  lib,
  ...
}:
let
  service = "copyparty";
  hl = config.homelab;
  cfg = hl.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";

    url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Domain to serve copyparty on";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3923;
      description = "Port for copyparty to listen on";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for copyparty to listen on";
    };

    volumesPath = lib.mkOption {
      type = lib.types.str;
      default = "/srv/copyparty";
      description = "Path to files to share";
    };

    # Pass through options to services.copyparty
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Settings to pass to services.copyparty.settings";
      example = lib.literalExpression ''
        {
          no-reload = true;
          e2d = true;
        }
      '';
    };

    accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          passwordFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing the password";
          };
        };
      });
      default = { };
      description = "User accounts for copyparty";
      example = lib.literalExpression ''
        {
          alice.passwordFile = "/run/secrets/copyparty-alice-password";
          bob.passwordFile = "/run/secrets/copyparty-bob-password";
        }
      '';
    };

    volumes = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Volume configuration for copyparty";
      example = lib.literalExpression ''
        {
          "/" = {
            path = "/srv/copyparty";
            access = {
              r = "*";
              rw = [ "alice" "bob" ];
            };
            flags = {
              fk = 4;
              scan = 60;
              e2d = true;
            };
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      settings = {
        i = cfg.listenAddress;
        p = [ cfg.port ];
      } // cfg.settings;

      accounts = cfg.accounts;
      volumes = cfg.volumes;
    };

    services.caddy.virtualHosts = lib.mkIf (cfg.url != null) {
      "${cfg.url}" = {
        useACMEHost = "avyay.in";
        extraConfig = ''
          reverse_proxy http://${cfg.listenAddress}:${toString cfg.port}
        '';
      };
    };
  };
}
