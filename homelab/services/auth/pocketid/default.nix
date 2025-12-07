{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homelab.services.auth.pocketid;
in {
  options.homelab.services.auth.pocketid = {
    enable = lib.mkEnableOption "Pocket ID OIDC Service";

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:1411";
      description = "The URL where you will access the app.";
    };

    trustProxy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the app is behind a reverse proxy.";
    };

    maxmindLicenseKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "License Key for the GeoLite2 Database.";
    };

    puid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "User ID for container permissions.";
    };

    pgid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Group ID for container permissions.";
    };

    dbProvider = lib.mkOption {
      type = lib.types.enum ["sqlite" "postgres"];
      default = "sqlite";
      description = "Database provider (sqlite or postgres).";
    };

    dbConnectionString = lib.mkOption {
      type = lib.types.str;
      default = "data/pocket-id.db";
      description = "Database connection string.";
    };

    uploadPath = lib.mkOption {
      type = lib.types.str;
      default = "data/uploads";
      description = "Path for uploaded files.";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum ["debug" "info" "warn" "error"];
      default = "info";
      description = "Log verbosity level.";
    };

    keysStorage = lib.mkOption {
      type = lib.types.enum ["file" "database"];
      default = "file";
      description = "Location to store private keys.";
    };

    encryptionKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Key used to encrypt data.";
    };

    keysPath = lib.mkOption {
      type = lib.types.str;
      default = "data/keys";
      description = "Path for storing private keys when using file storage.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 1411;
      description = "Port to listen on.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address to listen on.";
    };

    logJson = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable JSON formatted logs.";
    };

    unixSocket = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Unix socket path to listen on.";
    };

    unixSocketMode = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Unix socket mode.";
    };

    uiConfigDisabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable UI configuration.";
    };

    analyticsDisabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable analytics/heartbeat.";
    };

    # General Settings
    appName = lib.mkOption {
      type = lib.types.str;
      default = "Pocket ID";
      description = "The name of the app.";
    };

    sessionDuration = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Session duration in minutes.";
    };

    emailsVerified = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether user emails should be marked as verified.";
    };

    allowOwnAccountEdit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow users to edit their own account details.";
    };

    allowUserSignups = lib.mkOption {
      type = lib.types.enum ["disabled" "withToken" "open"];
      default = "disabled";
      description = "User signup functionality configuration.";
    };

    signupDefaultCustomClaims = lib.mkOption {
      type = lib.types.str;
      default = "[]";
      description = "Default custom claims for new users.";
    };

    signupDefaultUserGroupIds = lib.mkOption {
      type = lib.types.str;
      default = "[]";
      description = "Default group IDs for new users.";
    };

    # UI Settings
    disableAnimations = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable UI animations.";
    };

    accentColor = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Custom UI accent color.";
    };

    # SMTP Configuration
    smtp = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "SMTP server hostname.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 587;
        description = "SMTP server port.";
      };

      from = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Sender email address.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "SMTP username.";
      };

      password = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "SMTP password.";
      };

      

      tls = lib.mkOption {
        type = lib.types.enum ["none" "starttls" "tls"];
        default = "none";
        description = "SMTP TLS configuration.";
      };

      skipCertVerify = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Skip SMTP certificate verification.";
      };
    };

    # Email Notifications
    email = {
      loginNotification = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable login notification emails.";
      };

      oneTimeAccessAsAdmin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable admin one-time access codes.";
      };

      apiKeyExpiration = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable API key expiration emails.";
      };

      oneTimeAccessAsUnauthenticated = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable unauthenticated one-time access.";
      };
    };

    # LDAP Configuration
    ldap = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable LDAP authentication.";
      };

      url = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "LDAP server URL.";
      };

      bindDn = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "LDAP bind DN.";
      };

      bindPassword = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "LDAP bind password.";
      };

      

      base = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "LDAP search base DN.";
      };

      userSearchFilter = lib.mkOption {
        type = lib.types.str;
        default = "(objectClass=person)";
        description = "LDAP user search filter.";
      };

      userGroupSearchFilter = lib.mkOption {
        type = lib.types.str;
        default = "(objectClass=groupOfNames)";
        description = "LDAP group search filter.";
      };

      skipCertVerify = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Skip LDAP certificate verification.";
      };

      softDeleteUsers = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Disable rather than delete removed LDAP users.";
      };

      attributes = {
        userUniqueIdentifier = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for user unique identifier.";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for username.";
        };

        email = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for email.";
        };

        firstName = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for first name.";
        };

        lastName = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for last name.";
        };

        profilePicture = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for profile picture.";
        };

        groupMember = lib.mkOption {
          type = lib.types.str;
          default = "member";
          description = "LDAP attribute for group membership.";
        };

        groupUniqueIdentifier = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for group unique identifier.";
        };

        groupName = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP attribute for group name.";
        };

        adminGroup = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LDAP admin group name.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.pocketid = {
      enable = true;
      image = {
        repository = "ghcr.io/pocket-id/pocket-id:v1-distroless";
        tag = "v1";
      };
      ports = [
        {
          hostPort = cfg.port;
          containerPort = cfg.port;
        }
      ];
      volumes = [
        {
          hostPath = "${config.homelab.mounts.data}/pocketid/data";
          containerPath = "/app/data";
        }
      ];
      read_only = true;
      user = "1000:1000";
      environment = lib.mkMerge [
        {
          APP_URL = cfg.appUrl;
          TRUST_PROXY = toString cfg.trustProxy;
          MAXMIND_LICENSE_KEY = cfg.maxmindLicenseKey;
          PUID = toString cfg.puid;
          PGID = toString cfg.pgid;
          DB_PROVIDER = cfg.dbProvider;
          DB_CONNECTION_STRING = cfg.dbConnectionString;
          UPLOAD_PATH = cfg.uploadPath;
          LOG_LEVEL = cfg.logLevel;
          KEYS_STORAGE = cfg.keysStorage;
          ENCRYPTION_KEY = cfg.encryptionKey;
          KEYS_PATH = cfg.keysPath;
          PORT = toString cfg.port;
          HOST = cfg.host;
          LOG_JSON = toString cfg.logJson;
          UNIX_SOCKET = cfg.unixSocket;
          UNIX_SOCKET_MODE = cfg.unixSocketMode;
          UI_CONFIG_DISABLED = toString cfg.uiConfigDisabled;
          ANALYTICS_DISABLED = toString cfg.analyticsDisabled;

          # General Settings
          APP_NAME = cfg.appName;
          SESSION_DURATION = toString cfg.sessionDuration;
          EMAILS_VERIFIED = toString cfg.emailsVerified;
          ALLOW_OWN_ACCOUNT_EDIT = toString cfg.allowOwnAccountEdit;
          ALLOW_USER_SIGNUPS = cfg.allowUserSignups;
          SIGNUP_DEFAULT_CUSTOM_CLAIMS = cfg.signupDefaultCustomClaims;
          SIGNUP_DEFAULT_USER_GROUP_IDS = cfg.signupDefaultUserGroupIds;
          DISABLE_ANIMATIONS = toString cfg.disableAnimations;
          ACCENT_COLOR = cfg.accentColor;

          # SMTP Settings
          SMTP_HOST = cfg.smtp.host;
          SMTP_PORT = toString cfg.smtp.port;
          SMTP_FROM = cfg.smtp.from;
          SMTP_USER = cfg.smtp.user;
          SMTP_PASSWORD = cfg.smtp.password;
          SMTP_TLS = cfg.smtp.tls;
          SMTP_SKIP_CERT_VERIFY = toString cfg.smtp.skipCertVerify;

          # Email Notifications
          EMAIL_LOGIN_NOTIFICATION_ENABLED = toString cfg.email.loginNotification;
          EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = toString cfg.email.oneTimeAccessAsAdmin;
          EMAIL_API_KEY_EXPIRATION_ENABLED = toString cfg.email.apiKeyExpiration;
          EMAIL_ONE_TIME_ACCESS_AS_UNAUTHENTICATED_ENABLED = toString cfg.email.oneTimeAccessAsUnauthenticated;

          # LDAP Settings
          LDAP_ENABLED = toString cfg.ldap.enable;
          LDAP_URL = cfg.ldap.url;
          LDAP_BIND_DN = cfg.ldap.bindDn;
          LDAP_BIND_PASSWORD = cfg.ldap.bindPassword;
          LDAP_BASE = cfg.ldap.base;
          LDAP_USER_SEARCH_FILTER = cfg.ldap.userSearchFilter;
          LDAP_USER_GROUP_SEARCH_FILTER = cfg.tldap.userGroupSearchFilter;
          LDAP_SKIP_CERT_VERIFY = toString cfg.ldap.skipCertVerify;
          LDAP_SOFT_DELETE_USERS = toString cfg.ldap.softDeleteUsers;
          LDAP_ATTRIBUTE_USER_UNIQUE_IDENTIFIER = cfg.ldap.attributes.userUniqueIdentifier;
          LDAP_ATTRIBUTE_USER_USERNAME = cfg.ldap.attributes.username;
          LDAP_ATTRIBUTE_USER_EMAIL = cfg.ldap.attributes.email;
          LDAP_ATTRIBUTE_USER_FIRST_NAME = cfg.ldap.attributes.firstName;
          LDAP_ATTRIBUTE_USER_LAST_NAME = cfg.ldap.attributes.lastName;
          LDAP_ATTRIBUTE_USER_PROFILE_PICTURE = cfg.ldap.attributes.profilePicture;
          LDAP_ATTRIBUTE_GROUP_MEMBER = cfg.ldap.attributes.groupMember;
          LDAP_ATTRIBUTE_GROUP_UNIQUE_IDENTIFIER = cfg.ldap.attributes.groupUniqueIdentifier;
          LDAP_ATTRIBUTE_GROUP_NAME = cfg.ldap.attributes.groupName;
          LDAP_ATTRIBUTE_ADMIN_GROUP = cfg.ldap.attributes.adminGroup;
        }
      ];
    };
  };
}
