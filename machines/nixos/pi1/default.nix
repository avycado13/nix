{ pkgs, lib, config, ... }:
{
  imports = [ ./disko.nix ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  boot.tmp.cleanOnBoot = true;

  # Allow root SSH login for initial setup; override the shared default.
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

  # Use 1GB of additional swap memory
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];

  sops.secrets."wifi-password".key = "wifi/password";
  sops.templates."wireless.conf".content = ''
    psk_samosa=${config.sops.placeholder."wifi-password"}
  '';

  networking = {
    hostName = "pi1";
    wireless = {
      enable = true;
      secretsFile = config.sops.templates."wireless.conf".path;
      networks."samosa".pskRaw = "ext:psk_samosa";
      interfaces = [ "wlan0" ];
    };
  };

  users = {
    mutableUsers = false;
    users."pi" = {
      isNormalUser = true;
      password = "password";
      extraGroups = [ "wheel" ];
    };
    users.root.password = "root";
    # avy user comes from machines/nixos/default.nix; lock it on this host.
    users.avy.hashedPassword = "!";
  };

  system.stateVersion = "25.05";
}
