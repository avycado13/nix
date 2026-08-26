{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.fail2ban-cloudflare;
in
{
  options.services.fail2ban-cloudflare = {
    enable = lib.mkEnableOption "Enable fail2ban-cloudflare";

    apiKeyFile = lib.mkOption {
      description = "File containing your API key, scoped to Firewall Rules: Edit";
      type = lib.types.str;
      example = lib.literalExpression ''
        Authorization: Bearer Qj06My1wXJEzcW46QCyjFbSMgVtwIGfX63Ki3NOj79o=
      '';
    };

    zoneId = lib.mkOption {
      type = lib.types.str;
    };

    ignoreIP = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.0/8"
        "::1"
        # Tailscale CGNAT. Never ban over the tailnet -- it is the way back in
        # if a ban ever goes wrong.
        "100.64.0.0/10"
        "fd7a:115c:a1e0::/48"
        # RFC1918, so a flapping LAN client cannot lock the host out.
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
      description = "CIDRs fail2ban will never ban.";
    };

    jails = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            serviceName = lib.mkOption {
              example = "miniflux";
              type = lib.types.str;
            };

            failRegex = lib.mkOption {
              type = lib.types.str;
              example = "Login failed from IP: <HOST>";
            };

            ignoreRegex = lib.mkOption {
              type = lib.types.str;
              default = "";
            };

            maxRetry = lib.mkOption {
              type = lib.types.int;
              default = 3;
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      inherit (cfg) ignoreIP;

      extraPackages = [
        pkgs.curl
        pkgs.jq
      ];

      jails =
        let
          incrementalBan = {
            bantime = "1h";

            bantime-increment = {
              enable = true;
              formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
              maxtime = "168h";
              overalljails = true;
            };
          };
        in
        (lib.attrsets.mapAttrs (name: value: {
          settings = incrementalBan // {
            enabled = true;
            findtime = "1h";
            backend = "systemd";
            journalmatch = "_SYSTEMD_UNIT=${value.serviceName}.service";
            port = "http,https";
            filter = name;
            maxretry = value.maxRetry;
            action = "cloudflare-token-sops";
          };
        }) cfg.jails)
        // {
          sshd.settings = incrementalBan // {
            enabled = true;
            mode = "normal";
            port = "ssh";
            maxretry = 5;
            findtime = "10m";
          };
        };
    };

    environment.etc = lib.attrsets.mergeAttrsList [
      (lib.attrsets.mapAttrs' (
        name: value:
        lib.nameValuePair "fail2ban/filter.d/${name}.conf" {
          text = ''
            [Definition]
            failregex = ${value.failRegex}
            ignoreregex = ${value.ignoreRegex}
          '';
        }
      ) cfg.jails)

      {
        "fail2ban/action.d/cloudflare-token-sops.conf".text =
          let
            notes = "Fail2Ban on ${config.networking.hostName}";
            cfapi = "https://api.cloudflare.com/client/v4/zones/${cfg.zoneId}/firewall/access_rules/rules";
          in
          ''
            [Definition]
            actionstart =
            actionstop =
            actioncheck =

            actionunban = id=$(${lib.getExe pkgs.curl} -s -X GET "${cfapi}" \
                -H @${cfg.apiKeyFile} \
                -H "Content-Type: application/json" \
                | ${lib.getExe pkgs.jq} -r '.result[] | select(.notes == "${notes}" and .configuration.target == "ip" and .configuration.value == "<ip>") | .id')
                if [ -z "$id" ]; then
                  echo "id for <ip> cannot be found"
                  exit 0
                fi
                ${lib.getExe pkgs.curl} -s -X DELETE "${cfapi}/$id" \
                  -H @${cfg.apiKeyFile} \
                  -H "Content-Type: application/json" \
                  --data '{"cascade": "none"}'

            actionban = ${lib.getExe pkgs.curl} -s -X POST "${cfapi}" \
              -H @${cfg.apiKeyFile} \
              -H "Content-Type: application/json" \
              --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'

            [Init]
            name = cloudflare-token-sops
          '';
      }
    ];
  };
}
