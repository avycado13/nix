{ pkgs, config, ... }:
{
  imports = [ ./disko.nix ];

  # NixOS wants to enable GRUB by default

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  # Preserve space by sacrificing documentation and history
  documentation.nixos.enable = false;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";
  boot.cleanTmpDir = true;

  # Configure basic SSH access
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

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
    users.root = {
      password = "root";
    };
  };
  services.tailscale.enable = true;
  system.stateVersion = "25.05";
}
