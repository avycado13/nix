{ pkgs, ... }:
{
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
}
