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
    cloudflare-fail2ban-apikey = {
      sopsFile = ../../../secrets/secrets.yaml;
      key = "cloudflare/fail2ban_apikey";
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

    services = {
      enable = true;

      auth.enable = true;
      indiko = {
        domain = "auth.avyay.in";
        repository = "https://tangled.org/dunkirk.sh/indiko";
        branch = "main";
        autoUpdate = true;
      };

      miniflux = {
        enable = true;
        url = "news.avyay.in";
        adminCredentialsFile = config.sops.secrets.miniflux-admin-credentials.path;
      };
    };
  };
}
