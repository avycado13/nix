{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.email;
in
{
  options.email = {
    enable = lib.mkEnableOption "Email sending functionality";
    fromAddress = lib.mkOption {
      description = "The 'from' address";
      type = lib.types.str;
      default = "john@example.com";
    };
    toAddress = lib.mkOption {
      description = "The 'to' address";
      type = lib.types.str;
      default = "john@example.com";
    };
    smtpServer = lib.mkOption {
      description = "The SMTP server address";
      type = lib.types.str;
      default = "smtp.example.com";
    };
    smtpUsername = lib.mkOption {
      description = "The SMTP username";
      type = lib.types.str;
      default = "john@example.com";
    };
    smtpPasswordPath = lib.mkOption {
      description = "Path to the secret containing SMTP password";
      type = lib.types.path;
    };
    postfix.enable = lib.mkEnableOption "enable local postfix relay";
  };

  config = lib.mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      accounts.default = {
        auth = true;
        host = config.email.smtpServer;
        from = config.email.fromAddress;
        user = config.email.smtpUsername;
        tls = true;
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.email.smtpPasswordPath}";
      };
    };
    services.postfix = {
      enable = true;

      relayHost = "[${cfg.smtpServer}]:587";

      config = {
        # Only accept mail locally.
        inet_interfaces = "loopback-only";
        inet_protocols = "all";

        smtp_sasl_auth_enable = "yes";
        smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";

        smtp_sasl_security_options = "noanonymous";

        smtp_tls_security_level = "encrypt";
        smtp_tls_CAfile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        # Don't try to deliver directly to recipient MX servers.
        relayhost = "[${cfg.smtpServer}]:587";
      };

      # NixOS generates /etc/postfix/sasl_passwd from this.
      credentials = {
        "${cfg.smtpServer}:587" = {
          username = cfg.smtpUsername;
          passwordFile = cfg.smtpPasswordPath;
        };
      };
    };
  };
}
