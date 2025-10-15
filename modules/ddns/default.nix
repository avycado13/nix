{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.ddns;
in {
  options.ddns = {
    duckdns = {
      enable = mkEnableOption "DuckDNS Dynamic DNS Client";
      tokenFile = mkOption {
        default = null;
        type = types.path;
        description = ''
          The path to a file containing the token
          used to authenticate with DuckDNS.
        '';
      };

      domains = mkOption {
        default = null;
        type = types.nullOr (types.listOf types.str);
        example = ["examplehost"];
        description = ''
          The domain(s) to update in DuckDNS
          (without the .duckdns.org suffix)
        '';
      };

      domainsFile = mkOption {
        default = null;
        type = types.nullOr types.path;
        example = literalExpression ''
          pkgs.writeText "duckdns-domains.txt" '''
            examplehost
            examplehost2
            examplehost3
          '''
        '';
        description = ''
          The path to a file containing a
          newline-separated list of DuckDNS
          domain(s) to be updated
          (without the .duckdns.org suffix)
        '';
      };
    };

    cloudflare = {
      enable = mkEnableOption "Cloudflare Dynamic DNS Client";
      apiTokenFile = mkOption {
        default = null;
        type = types.path;
        description = ''
          The path to a file containing the API token
          used to authenticate with Cloudflare.
        '';
      };

      zoneId = mkOption {
        default = null;
        type = types.str;
        description = ''
          The Zone ID of the domain in Cloudflare.
        '';
      };

      recordName = mkOption {
        default = null;
        type = types.str;
        description = ''
          The full record name to update in Cloudflare (e.g., subdomain.example.com).
        '';
      };
    };
  };
  meta.maintainers = with lib.maintainers; [avycado13];
}
