{
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  # Pi 2 Model B rev 1.2 uses the 64-bit BCM2837 (unlike earlier Pi 2s).
  # The Pi 2 nixos-hardware module targets 32-bit armv7l instead.
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking = {
    hostName = "pi2";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi3;
  boot.swraid.enable = lib.mkForce false;
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.zfs.forceImportRoot = lib.mkForce false;

  nix-mineral.enable = lib.mkForce false;
  programs.nix-index.enable = lib.mkForce false;
  programs.nix-index-database.comma.enable = lib.mkForce false;
  services.smartd.enable = lib.mkForce false;
  services.timesyncd.enable = lib.mkForce true;

  sdImage.compressImage = true;
  zramSwap.enable = true;

  system.stateVersion = "25.11";
}
