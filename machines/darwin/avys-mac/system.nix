{
  # System-wide defaults
  system = {
    
    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        orientation = "bottom";
        showhidden = true;
        mineffect = "genie";
        mru-spaces = false;
        expose-group-apps = true;
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
      };

      # Trackpad settings
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
    };

    # System-wide keyboard settings
    keyboard = {
      enableKeyMapping = true;
    };

    activationScripts.postUserActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      launchctl stop com.apple.Dock.agent
      launchctl start com.apple.Dock.agent
    '';
  };
  launchd.daemons.apfs-cleanup = {
    # for whatever reason, rosetta keeps garbage around until we run this command
    script = ''
      date
      /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -P -minsize 0 /System/Volumes/Data
    '';
    serviceConfig = {
      StartCalendarInterval = [
        {
          Hour = 2;
          Minute = 30;
        }
      ];
      StandardErrorPath = "/var/log/apfs-cleanup.log";
      StandardOutPath = "/var/log/apfs-cleanup.log";
    };
  };
}
