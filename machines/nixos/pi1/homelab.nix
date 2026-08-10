{ config, ... }:
{
  sops.secrets = {
    cloudflare-dns-credentials = {
      sopsFile = ../../../secrets/secrets.yaml;
      key = "cloudflare/dns_credentials";
    };
    miniflux-admin-credentials = {
      sopsFile = ../../../secrets/services.yaml;
      key = "miniflux/admin_credentials";
    };
    miniflux-oauth-client-id = {
      sopsFile = ../../../secrets/services.yaml;
      key = "miniflux/oauth_client_id";
      mode = "0444";
    };
    miniflux-oauth-client-secret = {
      sopsFile = ../../../secrets/services.yaml;
      key = "miniflux/oauth_client_secret";
      mode = "0444";
    };
    cloudflare-fail2ban-apikey = {
      sopsFile = ../../../secrets/secrets.yaml;
      key = "cloudflare/fail2ban_apikey";
    };
    ntfy_topic = {
      sopsFile = ../../../secrets/secrets.yaml;
      key = "ntfy_topic";
    };
    # speedtest-tracker-app-key = {
    #   sopsFile = ../../../secrets/services.yaml;
    #   key = "speedtest-tracker/app_key";
    #   owner = "speedtest-tracker";
    # };
    xilo-env = {
      sopsFile = ../../../secrets/services.yaml;
      key = "xilo/env";
    };
    xilo-gcs-access-key = {
      sopsFile = ../../../secrets/services.yaml;
      key = "xilo/gcs_access_key";
    };
    xilo-gcs-secret-key = {
      sopsFile = ../../../secrets/services.yaml;
      key = "xilo/gcs_secret_key";
    };

    restic-repository-password = {
      sopsFile = ../../../secrets/services.yaml;
      key = "restic/repository_password";
    };
    restic-b2-credentials = {
      sopsFile = ../../../secrets/services.yaml;
      key = "restic/b2_credentials";
    };

    retrom-igdb-client-id = {
      sopsFile = ../../../secrets/services.yaml;
      key = "retrom/igdb_client_id";
    };
    retrom-igdb-client-secret = {
      sopsFile = ../../../secrets/services.yaml;
      key = "retrom/igdb_client_secret";
    };

    isponsorblocktv-living-room-tv-screen-id = {
      sopsFile = ../../../secrets/services.yaml;
      key = "isponsorblocktv/living_room_tv_screen_id";
    };

    lard-env = {
      sopsFile = ../../../secrets/services.yaml;
      key = "lard/env";
    };

  };

  services.fail2ban-cloudflare = {
    enable = true;
    zoneId = "4adc00cf91645d8c4abb10ae11b9c641";
    apiKeyFile = config.sops.secrets.cloudflare-fail2ban-apikey.path;
    # No jails configured yet -- add entries here once indiko emits a
    # journal line for failed logins (see homelab/fail2ban-cloudflare).
    jails = { };
  };

  homelab = {
    enable = true;
    baseDomainName = "avyay.in";
    email = "avycado13@icloud.com";
    cloudflare.dnsCredentialsFile = config.sops.secrets.cloudflare-dns-credentials.path;

    motd.enable = true;
    notifications.ntfySecretsFile = config.sops.secrets.ntfy_topic.path;

    services = {
      enable = true;

      auth.enable = true;
      indiko = {
        domain = "auth.avyay.in";
        repository = "https://tangled.org/dunkirk.sh/indiko";
        # repository = "https://tangled.org/avycado13.tngl.sh/indiko";
        branch = "main";
        autoUpdate = true;
      };

      miniflux = {
        enable = true;
        url = "news.avyay.in";
        adminCredentialsFile = config.sops.secrets.miniflux-admin-credentials.path;
        oauthClientIdFile = config.sops.secrets.miniflux-oauth-client-id.path;
        oauthClientSecretFile = config.sops.secrets.miniflux-oauth-client-secret.path;
      };

      glance = {
        enable = true;
        url = "glance.avyay.in";
      };

      xilo = {
        enable = true;
        url = "cache.avyay.in";
        environmentFile = config.sops.secrets.xilo-env.path;
        s3 = {
          enable = true;
          endpoint = "9de2baa272a57af74da84d8e6bd95a77.r2.cloudflarestorage.com";
          bucket = "nixcache";
        };
        storages.gcs = {
          endpoint = "storage.googleapis.com";
          bucket = "avycado13-nix-cache";
          accessKey = config.sops.placeholder.xilo-gcs-access-key;
          secretKey = config.sops.placeholder.xilo-gcs-secret-key;
        };
      };

      cloudrun = {
        enable = true;
        services = {
          searxng.cloudRunHost = "searxng-671676671649.europe-west1.run.app";
          it-tools.cloudRunHost = "it-tools-671676671649.europe-west1.run.app";
        };
      };

      retrom = {
        enable = false;
        url = "retrom.avyay.in";
        contentDirectories = [
          {
            path = "/var/lib/retrom/library";
            storageType = "MultiFileGame";
          }
        ];
        igdb = {
          clientId = config.sops.placeholder.retrom-igdb-client-id;
          clientSecret = config.sops.placeholder.retrom-igdb-client-secret;
        };
      };

      restic = {
        enable = true;
        repository = "b2:avyrestic:pi1";
        passwordFile = config.sops.secrets.restic-repository-password.path;
        environmentFile = config.sops.secrets.restic-b2-credentials.path;
      };

      scrutiny = {
        enable = true;
        domain = "scrutiny.avyay.in";
      };

      isponsorblocktv = {
        enable = true;
        devices = [
          {
            screenId = config.sops.placeholder.isponsorblocktv-living-room-tv-screen-id;
            name = "[LG] webOS TV OLED55C8PUA";
          }
        ];
        muteAds = true;
        skipAds = true;
      };

      lard = {
        enable = true;
        url = "lard.avyay.in";
        environmentFile = config.sops.secrets.lard-env.path;
        allowedUsers = [ "https://auth.avyay.in/u/avy" ];
      };

      calibre-web = {
        enable = true;
        url = "books.avyay.in";
      };
    };
  };
}
