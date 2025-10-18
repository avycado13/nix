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
}
