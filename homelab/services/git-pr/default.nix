let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "git-pr";
  description = "picosh/git-pr patch request service";
  defaultPort = 3000;
  runtime = "container";
  defaultImage = "ghcr.io/picosh/pico/git-pr:latest";

  extraOptions =
    { lib, ... }:
    {
      sshPort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = 2222;
        description = "Host port to expose git-pr SSH endpoint on";
      };
    };

  extraConfig =
    cfg:
    { lib, ... }:
    {
      homelab.services."git-pr".container = {
        volumes = [ "${cfg.dataDir}:/app/data" ];
        ports = lib.optional (cfg.sshPort != null) "${toString cfg.sshPort}:2222";
      };
    };
}
