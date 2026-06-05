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

  # Oracle Cloud optimizations
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  documentation.nixos.enable = false;

  # Tailscale for networking
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    git
  ];

  system.stateVersion = "25.05";

}
