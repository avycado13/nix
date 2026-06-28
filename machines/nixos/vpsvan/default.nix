{
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
  ];

  networking = {
    hostName = "vpsvan";
    hostId = "86d0ecdc";
    useDHCP = true;
  };

  users.users.avy.extraGroups = [
    "wheel"
    "docker"
  ];

  system.stateVersion = "25.05";
}
