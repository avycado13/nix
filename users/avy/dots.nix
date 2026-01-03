{
  inputs,
  ...
}: let
  home = {
    username = "avy";
    homeDirectory = "/home/avy";
    stateVersion = "25.05";
  };
in {
  nixpkgs = {
    overlays = [inputs.nix-topology.overlays.default inputs.lazygit.overlays.default];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = home;

  imports = [
    ./dotfiles/zsh/default.nix
    # ../../dots/nvim/default.nix
    ./dotfiles/ssh/default.nix
    ./packages.nix
    ./dotfiles/git/default.nix
    ./dotfiles/terminal/default.nix
    ./dotfiles/gpg/default.nix
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
}
