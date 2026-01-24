{
  config,
  lib,
  ...
}:
let
  cfg = config.binaryCache;
in
{
  options.binaryCache = {
    enable = lib.mkEnableOption "Nix binary cache and nix-serve setup";
    secretKeyFile = lib.mkOption {
      description = "Path to the private key file for the Nix binary cache";
      type = lib.types.path;
      default = "/var/secrets/cache-private-key.pem";
    };
    port = lib.mkOption {
      description = "Port for nix-serve to listen on";
      type = lib.types.int;
      default = 8080;
    };
  };

  config = lib.mkIf cfg.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = cfg.secretKeyFile;
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts.cache = {
        locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString cfg.port}/";
      };
    };

    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];
  };
}
