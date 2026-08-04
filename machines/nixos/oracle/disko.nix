{ lib, ... }:
{
  # Oracle Cloud Ubuntu image converted to NixOS via nixos-infect.
  # The disk was NOT partitioned by disko; the cloud image layout is:
  #   /dev/sda1  -> /         (ext4, cloudimg-rootfs)
  #   /dev/sda15 -> /boot/efi (vfat, UEFI ESP)
  # Declare fileSystems to match reality instead of using disko. mkForce is
  # needed because oci-common.nix (imported via oci-image.nix) also defines
  # fileSystems."/" and fileSystems."/boot" at normal priority, assuming a
  # by-label layout that doesn't match this disk.
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-uuid/cdf7e9dc-84a2-415d-983d-9d6afc5e84d5";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/892C-AA6D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
}
