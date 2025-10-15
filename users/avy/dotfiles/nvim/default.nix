{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
