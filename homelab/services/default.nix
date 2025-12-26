{
  config,
  lib,
  pkgs,
  ...
}: {
  options.homelab.services = {
    enable = lib.mkEnableOption "Containerized services for the homelab";
  };

  config = lib.mkIf config.homelab.services.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      autoPrune.enable = true;
      extraPackages = [pkgs.zfs];
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
    virtualisation.oci-containers = {
      backend = "podman";
    };

    networking.firewall.interfaces.podman0.allowedUDPPorts = [53];
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    security.acme = {
      acceptTerms = true;
      defaults.email = "${config.homelab.email}";
      certs.${config.homelab.baseDomain} = {
        reloadServices = ["caddy.service"];
        domain = "${config.homelab.baseDomain}";
        extraDomainNames = ["*.${config.homelab.baseDomain}"];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        group = config.services.caddy.group;
        environmentFile = config.homelab.cloudflare.dnsCredentialsFile;
      };
    };
    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
      '';
      virtualHosts = {
        "http://${config.homelab.baseDomain}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };
        "http://*.${config.homelab.baseDomain}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };
      };
    };
  };

  imports = [
    ./miniflux
    ./traefik
  ];
}
