let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "myspeed";
  description = "MySpeed - Speed test analysis software";
  defaultPort = 5216;
  runtime = "container";
  defaultImage = "germannewsmaker/myspeed:latest";

  extraConfig =
    cfg:
    { config, lib, ... }:
    {
      homelab.services.myspeed.container = {
        volumes = [ "${cfg.dataDir}:/myspeed/data" ];
      };

      homelab.services.myspeed.environment = {
        TZ = config.homelab.timeZone or "UTC";
      };
    };
}
