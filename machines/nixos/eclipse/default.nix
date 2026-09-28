{
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration (GRUB, BIOS + EFI hybrid)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "/dev/vda";
  };
  boot.tmp.cleanOnBoot = true;

  # /boot lives on the root partition (only /boot/efi is separate), so
  # nix-mineral's separate-partition hardening for it doesn't apply.
  nix-mineral.filesystems.normal."/boot".enable = false;

  # Serial console
  boot.kernelParams = [ "console=ttyS0,115200" ];

  networking = {
    hostName = "eclipse";
    useDHCP = true;
  };

  users.users.avy.extraGroups = [
    "wheel"
    "docker"
  ];

  system.stateVersion = "25.05";
}
