{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.homelab.services.postgres;
in
{
  options.homelab.services.postgres = {
    enable = lib.mkEnableOption "PostgreSQL database service";

    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "mydatabase" ];
      description = "List of databases to ensure are created.";
    };
    otherUsers = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "List of additional database users to create.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;

      ensureDatabases = cfg.databases;
      settings = {
        ssl = true;
      };

      authentication = lib.mkOverride 10 ''
          # TYPE  DATABASE  USER  ADDRESS         METHOD
          local   all       all                  trust
        host  sameuser    all     127.0.0.1/32 scram-sha-256
        host  sameuser    all     ::1/128 scram-sha-256
      '';
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      postgres  postgres
           # Let other names login as themselves
           superuser_map      /^(.*)$   \1
      '';
      initialScript = pkgs.writeText "postgres-init.sql" ''

      '';

      ensureUsers = [
        {
          name = "avy";
          ensureDBOwnership = true;
        }
      ]
      + map (
        u:
        if builtins.isString u then
          {
            name = u;
            ensureDBOwnership = true;
          }
        else
          u
      ) cfg.otherUsers;
    };
  };
}
