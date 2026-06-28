{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  # Boot configuration for Oracle Cloud (UEFI)
  # The cloud image ESP is mounted at /boot/efi, not /boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_scsi"
    "virtio_pci"
    "virtio_net"
  ];
  # Oracle Cloud ESP is not writable during nixos-rebuild; skip bootloader installation
  system.build.installBootLoader = lib.mkForce (pkgs.writeShellScript "no-bootloader" "exit 0");
  boot.tmp.cleanOnBoot = true;

  networking = {
    hostName = "oracle";
    hostId = "b3316d41";
    useDHCP = false;
    interfaces.ens3.useDHCP = true;
  };

  users.users.avy.extraGroups = [
    "wheel"
    "docker"
  ];

  system.stateVersion = "25.05";
}
