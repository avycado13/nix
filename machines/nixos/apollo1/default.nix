{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix-mineral.enable = lib.mkForce false;
  programs.nix-index.enable = lib.mkForce false;
  programs.nix-index-database.comma.enable = lib.mkForce false;
  services.smartd.enable = lib.mkForce false;

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
    ];
    tmp.cleanOnBoot = true;
    swraid.enable = lib.mkForce false;
    supportedFilesystems.zfs = lib.mkForce false;
    zfs.forceImportRoot = lib.mkForce false;
  };

  # U-Boot's SPL on Allwinner boards lives at a fixed raw offset before the
  # first partition (8KiB), so it has to be dd'd in after the sd-image is built.
  # No separate firmware partition is needed; extlinux.conf on the root
  # partition is what U-Boot reads to find the kernel.
  sdImage = {
    compressImage = true;
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
    postBuildCommands = ''
      dd if=${pkgs.ubootPine64}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
    '';
  };

  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

  networking.hostName = "apollo1";

  # AP6212 (brcmfmac) wifi behind the mmc1 SDIO bus enabled by the
  # pine64-wifi device tree overlay above.
  hardware.enableRedistributableFirmware = lib.mkForce true;

  sops.secrets.wifi-password = {
    sopsFile = ../../../secrets/secrets.yaml;
    key = "wifi/password";
  };
  sops.templates."wireless.conf" = {
    content = ''
      psk_samosa=${config.sops.placeholder.wifi-password}
    '';
    owner = "wpa_supplicant";
    mode = "0400";
  };
  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    secretsFile = config.sops.templates."wireless.conf".path;
    networks."samosa".pskRaw = "ext:psk_samosa";
  };

  services.tailscale.enable = true;
  services.timesyncd.enable = lib.mkForce true;
  services.getty.autologinUser = "avy";

  nixpkgs.hostPlatform = "aarch64-linux";

  # SD card storage is the tightest resource on this device, so garbage
  # collect and dedup aggressively rather than the repo-wide weekly/7d
  # defaults in modules/nix.
  nix = {
    settings = {
      min-free = lib.mkForce (128 * 1024 * 1024);
      max-free = lib.mkForce (1024 * 1024 * 1024);
    };
    gc = {
      automatic = lib.mkForce true;
      dates = lib.mkForce "daily";
      options = lib.mkForce "-d --delete-older-than 3d";
    };
    optimise = {
      automatic = lib.mkForce true;
      dates = lib.mkForce [ "daily" ];
    };
  };

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
