{pkgs,...}: {
  catppuccin = {
    enable = true;
    flavor = "mocha";
    vscode = {
      accent = "mauve";
      settings = {
        boldKeywords = true;
        italicComments = true;
        italicKeywords = true;
        colorOverrides = {};
        customUIColors = {};
        workbenchMode = "default";
        bracketMode = "rainbow";
        extraBordersEnabled = false;
      };
    };
  };
  fonts.fontconfig.enable = true;
  home.packages = [
   pkgs.nerd-fonts.open-dyslexic
  ];
}
