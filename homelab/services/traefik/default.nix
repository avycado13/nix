{ config, lib, pkgs, ... }:
let
  cfg = config.homelab.services.traefik;
  directories = [ "${cfg.mounts.config}" ];
  files = [ "${cfg.mounts.config}/acme.json" ];
in
{
  options.homelab.services.traefik = {
    enable = lib.mkEnableOption "Traefik reverse proxy";

    domainName = lib.mkOption {
      default = config.homelab.baseDomainName;
      type = lib.types.str;
      description = "Base domain name to be used for Traefik reverse proxy";
    };

    user = lib.mkOption {
      default = config.homelab.user;
      type = lib.types.str;
      description = "User to run Traefik as";
    };

    group = lib.mkOption {
      default = config.homelab.group;
      type = lib.types.str;
      description = "Group to run Traefik as";
    };

    timeZone = lib.mkOption {
      default = config.homelab.timeZone;
      type = lib.types.str;
      description = "Time zone to be used inside the Traefik container";
    };

    listenAddress = lib.mkOption {
      default = "0.0.0.0";
      type = lib.types.str;
      description = "IP that Traefik should listen on";
    };

    mounts.config = lib.mkOption {
      default = "${config.homelab.mounts.config}/traefik";
      type = lib.types.path;
      description = "Path to Traefik configs";
    };

    acme.dnsChallenge.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable the ACME DNS-01 challenge";
    };

    acme.dnsChallenge.provider = lib.mkOption {
      default = "cloudflare";
      type = lib.types.str;
      description = "DNS provider for ACME DNS-01 challenge";
    };

    acme.dnsChallenge.credentialsFile = lib.mkOption {
      default = "/dev/null";
      type = lib.types.path;
      description = ''
        Path to a file containing environment variables
        with DNS-01 credentials (provider-dependent)
        https://doc.traefik.io/traefik/https/acme/#providers
      '';
      example = lib.literalExpression ''
        pkgs.writeText "traefik-acme-credentials" '''
          CF_DNS_API_TOKEN=OyogTzFcPafhJ4hlleP9MMC-xA2sRs9MnUU68D3XkVQ
          CF_API_EMAIL=jane@doe.com
        '''
      '';
    };

    acme.email = lib.mkOption {
      default = null;
      type = lib.types.str;
      description = "Email for the ACME challenge";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure directories and files exist
    systemd.tmpfiles.rules =
      map (x: "d ${x} 0775 ${cfg.user} ${cfg.group} - -") directories
      ++ map (x: "f ${x} 0600 ${cfg.user} ${cfg.group} - -") files;

    # Enable OCI containers
    virtualisation.oci-containers.enable = true;

    virtualisation.oci-containers.containers = {
      # Docker socket proxy
      traefik-socket-proxy = {
        image = "ghcr.io/tecnativa/docker-socket-proxy:0.3.0";
        autoStart = true;
        extraOptions = [ "--pull=newer" ];
        volumes = [ "/var/run/podman/podman.sock:/var/run/docker.sock:ro" ];
        environment = {
          CONTAINERS = "1";
          POST = "0";
        };
      };

      # Traefik container
      traefik = {
        image = "traefik:latest";
        autoStart = true;
        cmd = [
          "--api.insecure=true"
          "--providers.docker=true"
          "--providers.docker.exposedbydefault=false"
          "--providers.docker.endpoint=tcp://traefik-socket-proxy:2375"
          "--entrypoints.web.address=:80"
          "--entrypoints.web.http.redirections.entrypoint.to=websecure"
          "--entrypoints.web.http.redirections.entrypoint.scheme=https"
          "--entrypoints.websecure.address=:443"
          "--entrypoints.websecure.http.tls=true"
          "--entrypoints.websecure.http.tls.certResolver=letsencrypt"
          "--entrypoints.websecure.http.tls.domains[0].main=${cfg.domainName}"
          "--entrypoints.websecure.http.tls.domains[0].sans=*.${cfg.domainName}"
          "--certificatesresolvers.letsencrypt.acme.dnschallenge=${builtins.toString cfg.acme.dnsChallenge.enable}"
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${cfg.acme.dnsChallenge.provider}"
          "--certificatesresolvers.letsencrypt.acme.email=${cfg.acme.email}"
        ];
        extraOptions = [ "--pull=newer" ];
        ports = [
          "${cfg.listenAddress}:443:443"
          "${cfg.listenAddress}:80:80"
        ];
        environmentFiles = [ cfg.acme.dnsChallenge.credentialsFile ];
        volumes = [ "${cfg.mounts.config}/acme.json:/acme.json" ];
      };
    };
  };
}