{ pkgs, ... }:
{
  imports = [ ./disko.nix ];

  # NixOS wants to enable GRUB by default

  environment.systemPackages = with pkgs; [
    raspberrypi-tools
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

  networking = {
    hostName = "pi1";
    wireless = {
      enable = true;
      networks."samosa".psk = "maplec29";
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
