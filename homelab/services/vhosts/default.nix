{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Generate a deterministic IPv6 address for a 64-bit prefix and seed string.
  # Prefix must not contain a trailing ':'.
  toIpv6Address =
    prefix64: seed:
    with builtins;
    let
      digest = hashString "sha256" seed;
      hextets = map (i: substring (4 * i) 4 digest) [
        0
        1
        2
        3
      ];
    in
    lib.concatStringsSep ":" ([ prefix64 ] ++ hextets);

  # Yggdrasil: get your prefix via `yggdrasilctl getself`
  yggPrefix = "300:ffff:ffff:ffff";

  # cjdns: fc00::/8 — derived deterministically from the seed
  # (in real use, the address comes from your cjdns private key;
  #  here we generate a stable stand-in for each vhost)
  cjdnsPrefix = "fc00:ffff:ffff:ffff";

  toYggAddress = toIpv6Address yggPrefix;
  toCjdnsAddress = toIpv6Address cjdnsPrefix;

in
{

  options.vhosts = lib.mkOption {
    description = ''
      Attrset of HTTP virtual-hosts to expose over Yggdrasil and/or cjdns,
      with Caddy as the reverse proxy and Cloudflare for DNS.
    '';
    type =
      with lib.types;
      attrsOf (
        submodule (
          { name, ... }:
          {
            options = {
              address = lib.mkOption {
                description = "Local listening address of the upstream service.";
                default = "127.0.0.1";
                type = str;
              };

              port = lib.mkOption {
                description = "Local listening port of the upstream service.";
                type = port;
              };

              yggdrasil = lib.mkOption {
                description = "Yggdrasil IPv6 address for this virtual-host.";
                type = str;
                default = toYggAddress name;
              };

              cjdns = lib.mkOption {
                description = "cjdns fc00::/8 IPv6 address for this virtual-host.";
                type = str;
                default = toCjdnsAddress name;
              };

              enableYggdrasil = lib.mkOption {
                description = "Expose this vhost over Yggdrasil.";
                type = bool;
                default = true;
              };

              enableCjdns = lib.mkOption {
                description = "Expose this vhost over cjdns.";
                type = bool;
                default = true;
              };

              # Cloudflare DNS options
              cloudflare = lib.mkOption {
                description = "Cloudflare DNS settings for this vhost.";
                type = submodule {
                  options = {
                    enable = lib.mkOption {
                      description = "Create Cloudflare AAAA records for this vhost.";
                      type = bool;
                      default = true;
                    };
                    zoneId = lib.mkOption {
                      description = "Cloudflare Zone ID.";
                      type = str;
                    };
                    apiTokenFile = lib.mkOption {
                      description = "Path to a file containing the Cloudflare API token.";
                      type = str;
                      default = "/run/secrets/cloudflare-api-token";
                    };
                  };
                };
              };
            };
          }
        )
      );
    default = { };
  };

  config =
    let
      vhostList = lib.attrsets.mapAttrsToList (name: cfg: cfg // { inherit name; }) config.vhosts;

      # All (address, prefixLength) pairs to assign to eth0
      ifaceAddresses = lib.concatMap (
        vh:
        lib.optional vh.enableYggdrasil {
          address = vh.yggdrasil;
          prefixLength = 64;
        }
        ++ lib.optional vh.enableCjdns {
          address = vh.cjdns;
          prefixLength = 8;
        }
      ) vhostList;

      # Build one Caddy virtual-host block per (vhost × network) combination.
      # Caddy listens on the overlay address and reverse-proxies to the local service.
      caddyVhostBlock = vh: network: addr: ''
        # ${vh.name} — ${network}
        http://${addr} {
          reverse_proxy ${vh.address}:${toString vh.port}
          log {
            output file /var/log/caddy/${vh.name}-${network}.log
          }
        }
      '';

      caddyConfig = lib.concatStrings (
        lib.concatMap (
          vh:
          lib.optional vh.enableYggdrasil (caddyVhostBlock vh "yggdrasil" vh.yggdrasil)
          ++ lib.optional vh.enableCjdns (caddyVhostBlock vh "cjdns" vh.cjdns)
        ) vhostList
      );

      # DNS records (Unbound, for local / Yggdrasil / cjdns resolvers)
      unboundRecords = lib.concatMap (
        vh:
        lib.optional vh.enableYggdrasil "${vh.name}.${config.fqdn} IN AAAA ${vh.yggdrasil}"
        ++ lib.optional vh.enableCjdns "${vh.name}.cjdns.${config.fqdn} IN AAAA ${vh.cjdns}"
      ) vhostList;

      # Cloudflare DNS sync: one systemd oneshot per vhost that has CF enabled.
      # Creates / updates AAAA records via the Cloudflare API.
      mkCfDnsService =
        vh:
        let
          mkRecord = network: addr: ''
            TOKEN=$(cat ${vh.cloudflare.apiTokenFile})
            ZONE=${vh.cloudflare.zoneId}
            HOSTNAME="${vh.name}.${config.fqdn}"

            # Look up existing record ID
            RECORD_ID=$(curl -sf \
              -H "Authorization: Bearer $TOKEN" \
              "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?type=AAAA&name=$HOSTNAME" \
              | ${lib.getExe pkgs.jq} -r '.result[0].id // empty')

            if [ -n "$RECORD_ID" ]; then
              # Update
              curl -sf -X PUT \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" \
                --data '{"type":"AAAA","name":"'"$HOSTNAME"'","content":"${addr}","ttl":120,"proxied":false}' \
                "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/$RECORD_ID"
            else
              # Create
              curl -sf -X POST \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" \
                --data '{"type":"AAAA","name":"'"$HOSTNAME"'","content":"${addr}","ttl":120,"proxied":false}' \
                "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records"
            fi
          '';
        in
        lib.optionalAttrs vh.cloudflare.enable {
          "cloudflare-dns-${vh.name}" = {
            description = "Sync Cloudflare DNS AAAA records for ${vh.name}";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = lib.concatStringsSep "\n" (
              lib.optional vh.enableYggdrasil (mkRecord "yggdrasil" vh.yggdrasil)
              ++ lib.optional vh.enableCjdns (mkRecord "cjdns" vh.cjdns)
            );
          };
        };

    in
    {

      # ── Network ────────────────────────────────────────────────────────────
      networking.interfaces.eth0.ipv6.addresses = ifaceAddresses;

      # ── Yggdrasil ─────────────────────────────────────────────────────────
      services.yggdrasil.enable = lib.any (vh: vh.enableYggdrasil) vhostList;

      # ── cjdns ─────────────────────────────────────────────────────────────
      services.cjdns.enable = lib.any (vh: vh.enableCjdns) vhostList;

      # ── Caddy ─────────────────────────────────────────────────────────────
      services.caddy = {
        enable = true;
        # Any site-wide Caddy config (TLS email, global options) goes here.
        extraConfig = caddyConfig;
      };

      # ── Local DNS (Unbound) ────────────────────────────────────────────────
      services.unbound = {
        enable = true;
        settings = {
          server = {
            local-zone = [ ''"${config.fqdn}" static'' ];
            local-data = map (s: ''"${s}"'') unboundRecords;
          };
        };
      };

      # ── Cloudflare DNS sync (systemd oneshots) ─────────────────────────────
      systemd.services = lib.foldl' (acc: vh: acc // mkCfDnsService vh) { } vhostList;

    };
}
