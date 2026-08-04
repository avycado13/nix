{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.dots.theme.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the theme dotfiles module.";
  };

  config = lib.mkIf config.dots.theme.enable {
    catppuccin = {
      autoEnable = true;
      enable = true;
      flavor = "mocha";
      vscode = {
        profiles.default = {
          accent = "mauve";
          settings = {
            boldKeywords = true;
            italicComments = true;
            italicKeywords = true;
            colorOverrides = { };
            customUIColors = { };
            workbenchMode = "default";
            bracketMode = "rainbow";
            extraBordersEnabled = false;
          };
        };
      };
    };
    fonts.fontconfig.enable = true;
    home.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
  };
}
