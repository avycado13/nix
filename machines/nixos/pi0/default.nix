{ ... }:
{
  nix.settings.trusted-users = [ "@wheel" ];
  system.stateVersion = "25.11";

  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      # ! Change the following to connect to your own network
      networks = {
        "samosa" = {
          psk = "maplec29";
        };
      };
    };
  };
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;
  users.users.avy = {
    isNormalUser = true;
    home = "/home/avy";
    description = "avy";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    # ! Be sure to put your own public key here
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPm9/uwsYQ2KrzaVcpulcDUKnBOCMCYogfC+D+TcrK7"
    ];
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "avy";

  # ! change the host name if you like
  networking.hostName = "pi0";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      workstation = true;
    };
  };
}
