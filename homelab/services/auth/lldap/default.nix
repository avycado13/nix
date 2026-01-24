{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.auth.lldap;
in
{
  options.homelab.services.auth.lldap = {
    enable = lib.mkEnableOption "LLDAP Authentication Service";

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "User ID for container permissions.";
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Group ID for container permissions.";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "Timezone for the container.";
    };

    jwtSecret = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "JWT secret used for authentication.";
    };

    keySeed = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Key seed for cryptographic operations.";
    };

    ldapBaseDn = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Base DN for LDAP queries.";
    };

    ldapUserPass = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "LDAP user password.";
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "sqlite:///data/lldap.db";
      description = "Database connection URL.";
    };

    smtpHost = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "SMTP server hostname (optional).";
    };

    smtpPort = lib.mkOption {
      type = lib.types.int;
      default = 587;
      description = "SMTP server port (optional).";
    };

    smtpUser = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "SMTP username (optional).";
    };

    smtpPassword = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "SMTP password (optional).";
    };

    ldapsEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable LDAPS (LDAP over SSL).";
    };

    ldapsCertPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to LDAPS certificate (optional).";
    };

    verbose = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable verbose logging.";
    };

    ldapHost = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "LDAP server bind address.";
    };

    ldapPort = lib.mkOption {
      type = lib.types.port;
      default = 3890;
      description = "LDAP server port.";
    };

    httpHost = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "HTTP server bind address.";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 17170;
      description = "HTTP server port.";
    };

    httpUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost";
      description = "Public URL of the server for password reset links.";
    };

    assetsPath = lib.mkOption {
      type = lib.types.str;
      default = "./app";
      description = "Path to front-end assets.";
    };

    ldapUserEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Admin email address.";
    };

    ldapUserDn = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Admin username for LDAP interface.";
    };

    forceLdapUserPassReset = lib.mkOption {
      type = lib.types.either lib.types.bool (lib.types.enum [ "always" ]);
      default = false;
      description = "Force reset of admin password.";
    };

    ignoredUserAttributes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "LDAP user attributes to ignore.";
    };

    ignoredGroupAttributes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "LDAP group attributes to ignore.";
    };

    smtp = {
      enablePasswordReset = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable password reset via email.";
      };

      encryption = lib.mkOption {
        type = lib.types.enum [
          "NONE"
          "TLS"
          "STARTTLS"
        ];
        default = "TLS";
        description = "SMTP encryption type.";
      };

      from = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "From header for emails.";
      };

      replyTo = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Reply-To header for emails.";
      };
    };

    ldaps = {
      keyPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to LDAPS key file.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.lldap = {
      enable = true;
      image = {
        repository = "lldap/lldap";
        tag = "stable";
      };
      ports = [
        {
          hostPort = 17170;
          containerPort = 17170;
        }
        {
          hostPort = 6360;
          containerPort = 6360;
        }
      ];
      volumes = [
        {
          hostPath = "${config.homelab.mounts.data}/lldap/data";
          containerPath = "/data";
        }
      ];
      environment = {
        LLDAP_UID = toString cfg.uid;
        LLDAP_GID = toString cfg.gid;
        LLDAP_TIMEZONE = cfg.timezone;
        LLDAP_JWT_SECRET = cfg.jwtSecret;
        LLDAP_KEY_SEED = cfg.keySeed;
        LLDAP_LDAP_BASE_DN = cfg.ldapBaseDn;
        LLDAP_LDAP_USER_PASS = cfg.ldapUserPass;
        LLDAP_DATABASE_URL = cfg.databaseUrl;
        LLDAP_SMTP_OPTIONS__HOST = cfg.smtpHost;
        LLDAP_SMTP_OPTIONS__PORT = toString cfg.smtpPort;
        LLDAP_SMTP_OPTIONS__USER = cfg.smtpUser;
        LLDAP_SMTP_OPTIONS__PASSWORD = cfg.smtpPassword;
        LLDAP_LDAPS_OPTIONS__ENABLED = toString cfg.ldapsEnabled;
        LLDAP_LDAPS_OPTIONS__CERT_PATH = cfg.ldapsCertPath;
        LLDAP_VERBOSE = toString cfg.verbose;
        LLDAP_LDAP_HOST = cfg.ldapHost;
        LLDAP_LDAP_PORT = toString cfg.ldapPort;
        LLDAP_HTTP_HOST = cfg.httpHost;
        LLDAP_HTTP_PORT = toString cfg.httpPort;
        LLDAP_HTTP_URL = cfg.httpUrl;
        LLDAP_ASSETS_PATH = cfg.assetsPath;
        LLDAP_LDAP_USER_EMAIL = cfg.ldapUserEmail;
        LLDAP_LDAP_USER_DN = cfg.ldapUserDn;
        LLDAP_FORCE_LDAP_USER_PASS_RESET = toString cfg.forceLdapUserPassReset;
        LLDAP_IGNORED_USER_ATTRIBUTES = builtins.toJSON cfg.ignoredUserAttributes;
        LLDAP_IGNORED_GROUP_ATTRIBUTES = builtins.toJSON cfg.ignoredGroupAttributes;

        # SMTP additions
        LLDAP_SMTP_OPTIONS__ENABLE_PASSWORD_RESET = toString cfg.smtp.enablePasswordReset;
        LLDAP_SMTP_OPTIONS__SMTP_ENCRYPTION = cfg.smtp.encryption;
        LLDAP_SMTP_OPTIONS__FROM = cfg.smtp.from;
        LLDAP_SMTP_OPTIONS__REPLY_TO = cfg.smtp.replyTo;

        # LDAPS additions
        LLDAP_LDAPS_OPTIONS__KEY_PATH = cfg.ldaps.keyPath;
      };
    };
  };
}
