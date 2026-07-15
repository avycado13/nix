{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  helpers = import ../../flakeHelpers.nix inputs;
in
{
  nixpkgs = helpers.nixpkgsCfg;
  imports = [ ../../modules/nix/default.nix ];

  nix-mineral = {
    enable = true;
    preset = "compatibility";
  };

  # Monitor disk health where drives are present; no-op on VMs/SD cards
  services.smartd = {
    enable = true;
    autodetect = true;
  };

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
    extraGroups = lib.mkDefault [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPm9/uwsYQ2KrzaVcpulcDUKnBOCMCYogfC+D+TcrK7"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  time.timeZone = "America/Los_Angeles";

  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
  };

  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    git
  ];
}
