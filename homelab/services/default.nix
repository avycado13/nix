{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.homelab.services = {
    enable = lib.mkEnableOption "Containerized services for the homelab";
  };

  config = lib.mkIf config.homelab.services.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      autoPrune.enable = true;
      extraPackages = [ ];
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
    virtualisation.oci-containers = {
      backend = "podman";
    };

    networking.firewall.interfaces.podman0.allowedUDPPorts = [ 53 ];
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    security.acme = {
      acceptTerms = true;
      defaults.email = "${config.homelab.email}";
      certs.${config.homelab.baseDomainName} = {
        reloadServices = [ "caddy.service" ];
        domain = "${config.homelab.baseDomainName}";
        extraDomainNames = [ "*.${config.homelab.baseDomainName}" ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        group = config.services.caddy.group;
        environmentFile = config.homelab.cloudflare.dnsCredentialsFile;
      };
    };
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/powerdns@v1.0.1" ];
        hash = "sha256-F/jqR4iEsklJFycTjSaW8B/V3iTGqqGOzwYBUXxRKrc=";
      };
      globalConfig = ''
        auto_https off
      '';
      virtualHosts = {
        "https://${config.homelab.baseDomainName}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };
        "http://*.${config.homelab.baseDomainName}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };
      };
    };
  };

  imports = [
    ./miniflux
    ./git-pr
  ];
}
