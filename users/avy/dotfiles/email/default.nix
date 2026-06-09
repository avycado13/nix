{
  config,
  pkgs,
  ...
}:
{
  # Email: mbsync (sync), msmtp (send), neomutt (read)
  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.neomutt = {
    enable = true;
    vimKeys = true;
  };
  programs.notmuch = {
    enable = true;
    hooks.preNew = "mbsync --all";
  };
  services.imapnotify.enable = true;

  # Calendar & Contacts: vdirsyncer (sync), khal (calendar), khard (contacts)
  programs.vdirsyncer.enable = true;
  services.vdirsyncer.enable = true;
  programs.khal = {
    enable = true;
    locale = {
      dateformat = "%Y-%m-%d";
      timeformat = "%H:%M";
    };
  };
  programs.khard.enable = true;

  accounts.email = {
    maildirBasePath = "Mail";
    accounts.icloud = {
      primary = true;
      address = "avycado13@icloud.com";
      userName = "avycado13";
      realName = "Avy";
      imap = {
        host = "imap.mail.me.com";
        port = 993;
        tls.enable = true;
      };
      gpg = {
        key = "680098B290681E1D28F555A90F7A57CF72410272";
        signByDefault = true;
      };
      passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.icloud_email_password.path}";
      smtp = {
        host = "smtp.mail.me.com";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };
      mbsync = {
        enable = true;
        create = "maildir";
      };
      msmtp.enable = true;
      neomutt.enable = true;
      aerc.enable = true;
      notmuch.enable = true;
      imapnotify = {
        enable = true;
        boxes = [ "INBOX" ];
        onNotify = "${pkgs.isync}/bin/mbsync icloud";
        onNotifyPost = "${pkgs.notmuch}/bin/notmuch new";
      };
    };
  };

  accounts.contact = {
    basePath = "Contacts";
    accounts.icloud = {
      remote = {
        type = "carddav";
        url = "https://contacts.icloud.com";
        userName = "avycado13@icloud.com";
        passwordCommand = [
          "${pkgs.coreutils}/bin/cat"
          "${config.sops.secrets.icloud_email_password.path}"
        ];
      };
      vdirsyncer.enable = true;
      khard.enable = true;
    };
  };

  accounts.calendar = {
    basePath = "Calendars";
    accounts.icloud = {
      primary = true;
      primaryCollection = "calendar";
      remote = {
        type = "caldav";
        url = "https://caldav.icloud.com";
        userName = "avycado13@icloud.com";
        passwordCommand = [
          "${pkgs.coreutils}/bin/cat"
          "${config.sops.secrets.icloud_email_password.path}"
        ];
      };
      vdirsyncer.enable = true;
      khal.enable = true;
    };
  };
}
