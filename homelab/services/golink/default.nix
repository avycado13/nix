{ config, pkgs, lib, ... }:

let
  cfg = config.homelab.services.golink;
in
{
  options.homelab.services.golink = {
    enable = lib.mkEnableOption "GoLink Service";

    # Optional: you can expose a listen address if you want
    listenAddr = lib.mkOption {
      type = lib.types.str;
      default = ":8080";
      description = "Address GoLink listens on";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.golink = {
      enable = true;

      image = {
        repository = "ghcr.io/tailscale/golink";
        tag = "main";
      };


      # Development mode arguments
      command = [ "-dev-listen" cfg.listenAddr ];

      # Optional: make it interactive or remove on exit like `--rm -it`
      tty = true;
      autoRemove = true;
    };
  };
}