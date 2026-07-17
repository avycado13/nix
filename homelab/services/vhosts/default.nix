{ config, lib, ... }:

let
  cfg = config.homelab.vhosts;
in
{

  options.homelab.vhosts = {
    enable = lib.mkEnableOption "Virtual hosts, published via `tailscale serve`";

    hosts = lib.mkOption {
      description = "Attrset of HTTP virtual-hosts to publish over Tailscale.";
      default = { };
      type =
        with lib.types;
        attrsOf (submodule {
          options = {
            address = lib.mkOption {
              description = "Local listening address of service.";
              default = "127.0.0.1";
              type = str;
            };
            port = lib.mkOption {
              description = "Local listening port of service. Also used as the tailnet HTTPS port this vhost is published on.";
              type = port;
            };
          };
        });
    };
  };

  config = lib.mkIf cfg.enable {

    services.tailscale.enable = true;

    # `tailscale serve` config lives in tailscaled's state, not in a NixOS
    # option, so apply it imperatively on every activation. Each host gets
    # its own HTTPS port on this node's tailnet name (MagicDNS), since a
    # single tailnet hostname can't be split across multiple names the way
    # Yggdrasil's per-service addresses allowed.
    systemd.services.homelab-tailscale-serve = {
      description = "Publish homelab vhosts via tailscale serve";
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = lib.concatStringsSep "\n" (
        [ "set -eu" ]
        ++ lib.attrsets.mapAttrsToList (
          _name:
          { address, port }:
          "${config.services.tailscale.package}/bin/tailscale serve --bg --https=${toString port} http://${address}:${toString port}"
        ) cfg.hosts
      );
    };
  };
}
