{
  config,
  lib,
  ...
}:
let
  service = "xilo";
  hl = config.homelab;
  cfg = hl.services.${service};
  port = 8080;

  usesTemplate = cfg.storages != { };

  baseSettings = {
    listen = "127.0.0.1:${toString port}";
    base_url = "https://${cfg.url}";
    data_dir = "/var/lib/xilo";
  }
  // lib.optionalAttrs cfg.s3.enable {
    storage = {
      backend = "s3";
      s3 = {
        endpoint = cfg.s3.endpoint;
        bucket = cfg.s3.bucket;
        region = cfg.s3.region;
      };
    };
  }
  // lib.optionalAttrs usesTemplate {
    storages = lib.mapAttrs (_name: s: {
      backend = "s3";
      s3 = {
        endpoint = s.endpoint;
        bucket = s.bucket;
        region = s.region;
        access_key = s.accessKey;
        secret_key = s.secretKey;
      };
    }) cfg.storages;
  }
  // lib.optionalAttrs (cfg.defaultStorage != null) {
    default_storage = cfg.defaultStorage;
  };
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}, a self-hosted Nix binary cache";
    url = lib.mkOption {
      type = lib.types.str;
      default = "cache.${hl.baseDomainName}";
      description = "Domain to serve xilo on";
    };
    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        EnvironmentFile containing XILO_ADMIN_PASSWORD and, when the s3
        backend is used, XILO_S3_ACCESS_KEY / XILO_S3_SECRET_KEY.
      '';
    };
    s3 = {
      enable = lib.mkEnableOption "Store xilo's chunks in an S3-compatible bucket instead of local disk";
      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "S3 endpoint host, e.g. \"<account-id>.r2.cloudflarestorage.com\" for R2";
      };
      bucket = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "S3 bucket name";
      };
      region = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        description = "S3 region; R2 always uses \"auto\"";
      };
    };
    storages = lib.mkOption {
      default = { };
      description = ''
        Additional named S3 backends beyond the primary "default" one (set
        via the `s3` option above). Each cache is pinned to one backend at
        creation. Since xilo has no env-var override for these, pass
        `accessKey`/`secretKey` as `config.sops.placeholder.<name>` values so
        they land in a sops-rendered config file (see below) instead of
        plain text in the Nix store.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            endpoint = lib.mkOption {
              type = lib.types.str;
              description = "S3 endpoint host, e.g. \"storage.googleapis.com\"";
            };
            bucket = lib.mkOption {
              type = lib.types.str;
              description = "S3 bucket name";
            };
            region = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              description = "S3 region";
            };
            accessKey = lib.mkOption {
              type = lib.types.str;
              description = "S3 access key, e.g. config.sops.placeholder.\"xilo-<name>-access-key\"";
            };
            secretKey = lib.mkOption {
              type = lib.types.str;
              description = "S3 secret key, e.g. config.sops.placeholder.\"xilo-<name>-secret-key\"";
            };
          };
        }
      );
    };
    defaultStorage = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Name of the backend (a key of `storages`) new caches use by
        default. Null keeps the primary "default" storage as default.
      '';
    };
    glance.name = lib.mkOption {
      type = lib.types.str;
      default = "Xilo";
    };
    glance.url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "https://${cfg.url}";
      description = "URL to show for this service in the Glance homelab bookmarks";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xilo = {
      enable = true;
      environmentFile = cfg.environmentFile;
      # When extra storages carry secret placeholders, config is instead
      # rendered via sops.templates below and loaded through
      # LoadCredential, so this Nix-store-embedded settings block is
      # skipped entirely to avoid baking unresolved placeholder text in.
      settings = lib.mkIf (!usesTemplate) baseSettings;
    };

    # sops-nix placeholders are only substituted inside declared templates,
    # never inside arbitrary store paths -- so when secrets are involved we
    # bypass the upstream module's Nix-store-rendered config file and
    # render our own via sops, then hand it to the (DynamicUser) service
    # through systemd's LoadCredential, which systemd (as root) copies into
    # a private, correctly-permissioned directory before dropping to the
    # service's dynamic user.
    sops.templates."xilo-config.yaml" = lib.mkIf usesTemplate {
      content = builtins.toJSON baseSettings;
    };

    systemd.services.${service}.serviceConfig =
      lib.optionalAttrs usesTemplate {
        LoadCredential = [
          "config.yaml:${config.sops.templates."xilo-config.yaml".path}"
        ];
        ExecStart = lib.mkForce "${lib.getExe config.services.xilo.package} serve --config %d/config.yaml";
      }
      // lib.optionalAttrs (hl.notifications.ntfySecretsFile != null) {
        OnFailure = "notify-failure@%n.service";
      };

    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
        request_body {
          max_size 0
        }
      '';
    };
    services.nix-cache-beacon = {
      # Announce cache to the local network
      advert = {
        enable = true;
        port = port; # xilo port
      };

      # Enable local binary cache using discovered caches on the local network
      cache.enable = true;
    };
  };
}
