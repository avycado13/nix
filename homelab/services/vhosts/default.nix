{ config, lib, ... }:

let
  # Generate a deterministic IPv6 address for a 64 bit prefix
  # and seed string. Prefix must not contain trailing ':'.
  toIpv6Address =
    prefix64: seed:
    with builtins;
    let
      digest = builtins.hashString "sha256" seed;
      hextets = map (i: substring (4 * i) 4 digest) [
        0
        1
        2
        3
      ];
    in
    concatStringsSep ":" ([ prefix64 ] ++ hextets);

  # Get this prefix by running `yggdrasilctl getself`.
  yggPrefix = "300:ffff:ffff:ffff";

  toIpv6Address' = toIpv6Address yggPrefix;
in
{

  options.vhosts = lib.mkOption {
    description = "Attrset of HTTP virtual-hosts to create Yggdrasil addresses for.";
    type =
      with lib.types;
      attrsOf (
        submodule (
          { name, ... }: {
            options = {
              address = lib.mkOption {
                description = "Local listening address of service.";
                default = "127.0.0.1";
                type = str;
              };
              port = lib.mkOption {
                description = "Local listening port of service.";
                type = port;
              };
              yggdrasil = lib.mkOption {
                description = "Yggdrasil address to create for this virtual-host";
                type = str;
                default = toIpv6Address' name;
              };
            };
          }
        )
      );
  };

  config = {

    # Add generated addresses eth0
    networking.interfaces.eth0 = lib.attrsets.mapAttrsToList (_name: { yggdrasil, ... }: {
      address = yggdrasil;
      prefixLength = 64;
    }) config.vhosts;

    # Configure Squid to proxy generated addresses to the local services.
    services.squid = {
      enable = true;
      extraConfig = ''
        acl yggdrasil src 200::/8
        http_port 80 accel
        http_access allow yggdrasil

      ''
      + (toString (
        lib.attrsets.mapAttrsToList (
          name:
          {
            address,
            port,
            yggdrasil,
          }:
          ''

            acl ${name}-address dst ${yggdrasil}
            acl ${name}-domain dstdomain ${name}.${config.fqdn}
            cache_peer ${address} parent ${toString port} 0 no-query originserver name=${name}-peer
            cache_peer_access ${name}-peer allow ${name}-address
            cache_peer_access ${name}-peer allow ${name}-domain
            cache_peer_access ${name}-peer deny all
            http_access allow ${name}-address
            http_access allow ${name}-domain
          ''
        ) config.vhosts
      ));
    };

    # Add DNS records for the generated addresses.
    # This assumes this server is configure as the nameserver for ${config.fqdn}.
    services.unbound = {
      enable = true;
      settings = {
        server = {
          local-zone = [ ''"${config.fqdn}" static'' ];
          local-data = map (s: ''"${s}"'') (
            lib.attrsets.mapAttrsToList (
              name: { yggdrasil, ... }: "${name}.${config.fqdn} IN AAAA ${yggdrasil}"
            ) config.vhosts
          );
        };

      };
    };

  };
}
