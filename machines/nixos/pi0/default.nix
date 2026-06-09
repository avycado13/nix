{
  lib,
  config,
  pkgs,
  ...
}:
{
  programs.nix-index.enable = lib.mkForce false;
  programs.nix-index-database.comma.enable = lib.mkForce false;
  # home-manager.users.avy.programs.nix-index.enable = lib.mkForce false;
  # home-manager.users.avy.programs.nix-index-database.comma.enable = lib.mkForce false;
  # home-manager.users.avy.catppuccin.enable = lib.mkForce false;
  nix.settings.trusted-users = [ "@wheel" ];
  system.stateVersion = "25.11";

  sops.secrets."wifi-password".key = "wifi/password";
  sops.templates."wireless.conf".content = ''
    psk_samosa=${config.sops.placeholder."wifi-password"}
  '';

  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      secretsFile = config.sops.templates."wireless.conf".path;
      # ! Change the following to connect to your own network
      networks = {
        "samosa" = {
          pskRaw = "ext:psk_samosa";
        };
      };
    };
  };
  services.sshd.enable = true;
  services.tailscale.enable = true;
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  # NTP time sync.
  services.timesyncd.enable = lib.mkForce true;
  users.users.avy = {
    isNormalUser = true;
    home = "/home/avy";
    description = "avy";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    # ! Be sure to put your own public key here
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPm9/uwsYQ2KrzaVcpulcDUKnBOCMCYogfC+D+TcrK7"
    ];
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "avy";

  # ! change the host name if you like
  networking.hostName = "pi0";

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

  image.fileName = "zero2.img";
  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
    compressImage = true;

    populateFirmwareCommands = lib.mkAfter ''
      config=firmware/config.txt
      chmod u+w $config
      echo "" >> $config
      echo "# Extra configuration" >> $config
      echo "start_x=0" >> $config
      echo "gpu_mem=16" >> $config
      echo "hdmi_group=2" >> $config
      echo "hdmi_mode=8" >> $config
      chmod u-w $config
    '';
  };

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  hardware = {
    enableRedistributableFirmware = lib.mkForce false;
    firmware = [ pkgs.raspberrypiWirelessFirmware ]; # Keep this to make sure wifi works
    i2c.enable = true;

    deviceTree = {
      enable = true;
      kernelPackage = pkgs.linuxKernel.packages.linux_rpi3.kernel;
      filter = "*2837*";

      overlays = [
        {
          name = "enable-i2c";
          dtsFile = ./dts/i2c.dts;
        }
        {
          name = "pwm-2chan";
          dtsFile = ./dts/pwm.dts;
        }
        {
          name = "spi1-2cs";
          dtsFile = ./dts/spi.dts;
        }
      ];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi02w;

    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;
  };

}
