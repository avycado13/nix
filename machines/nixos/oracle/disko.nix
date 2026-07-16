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
    device = "/dev/disk/by-uuid/e589f498-db66-4f31-b742-997eddb4ee7d";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/B8AD-01FE";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };
}
