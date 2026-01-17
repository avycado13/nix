{
  inputs,
  pkgs,
  ...
}: let
  home = {
    username = "avy";
    homeDirectory = "/home/avy";
    stateVersion = "25.05";
  };
in {
  nixpkgs = {
    overlays = [
      inputs.nix-topology.overlays.default
      inputs.lazygit.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      inputs.nur.overlays.default
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = home;

  imports = [
    ./dotfiles/zsh/default.nix
    ./dotfiles/editor/default.nix
    ./dotfiles/ssh/default.nix
    ./packages.nix
    ./dotfiles/git/default.nix
    ./dotfiles/terminal/default.nix
    ./dotfiles/gpg/default.nix
    ./dotfiles/devenv/default.nix
    ./dotfiles/theme/default.nix
  ];

  programs.home-manager.enable = true;
  services.home-manager = {
    autoExpire = {
      enable = true;
      store = {
        cleanup = true;
        options = "--delete-older-than 14d";
      };
    };
    autoUpgrade = {
      enable = false;
      flakeDir = "~/nix";
      useFlake = true;
    };
  };

  systemd.user.startServices = "sd-switch";
}
