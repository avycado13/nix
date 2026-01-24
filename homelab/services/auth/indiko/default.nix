{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.auth.indiko;
in
{
  options.homelab.services.auth.indiko = {
    enable = lib.mkEnableOption "indiko OAuth/IndieAuth server";

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:1411";
      description = "The URL where you will access the app.";
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
