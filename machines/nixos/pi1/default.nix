{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./homelab.nix
  ];
  # Disable modules that conflict with SD image builds or are inappropriate
  # for a small embedded device.
  nix-mineral.enable = lib.mkForce false;
  programs.nix-index.enable = lib.mkForce false;
  programs.nix-index-database.comma.enable = lib.mkForce false;
  services.smartd.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  boot = {
    tmp.cleanOnBoot = true;
    swraid.enable = lib.mkForce false;
    supportedFilesystems.zfs = lib.mkForce false;
    zfs.forceImportRoot = lib.mkForce false;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
  };

  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024; # size in MiB
    }
  ];

  networking = {
    hostName = "pi1";
    useDHCP = false;
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      networks."samosa".psk = "maplec29";
    };
    firewall.allowedUDPPorts = [ config.services.tailscale.port ];
    # Comcast blocks inbound IPv4 port forwarding, so *.avyay.in is served
    # directly over pi1's public IPv6 address instead. Disable privacy
    # extensions so that address stays stable for DNS instead of rotating.
    tempAddresses = "disabled";
  };

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

  services.tailscale.enable = true;
  services.timesyncd.enable = lib.mkForce true;
  services.getty.autologinUser = "avy";

  hardware = {
    enableRedistributableFirmware = lib.mkForce true;
    firmware = [ pkgs.raspberrypiWirelessFirmware ];
  };

  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  sdImage.compressImage = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  users = {
    mutableUsers = false;
    users.root.password = "root";
    users.avy.hashedPassword = "!";
  };

  system.stateVersion = "25.05";
}
