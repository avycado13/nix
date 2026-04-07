{
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  # Boot configuration (GRUB, BIOS + EFI hybrid)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "/dev/vda";
  };
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
  ];
  boot.tmp.cleanOnBoot = true;

  # Serial console
  boot.kernelParams = [ "console=ttyS0,115200" ];

  networking = {
    hostName = "eclipse";
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };
  };

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.avy = {
    isNormalUser = true;
    home = "/home/avy";
    description = "avy";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPm9/uwsYQ2KrzaVcpulcDUKnBOCMCYogfC+D+TcrK7"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  documentation.nixos.enable = false;

  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    git
  ];

  system.stateVersion = "25.05";
}
