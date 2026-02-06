{ pkgs, ... }:
{
  programs = {
    bun = {
      enable = true;
      enableGitIntegration = true;
    };
    ruff = {
      enable = true;
      settings = {
        line-length = 100;
        per-file-ignores = {
          "__init__.py" = [ "F401" ];
        };
        lint = {
          select = [ ];
          ignore = [ ];
        };
      };
    };
    ty = {
      enable = true;
    };
  };
  home.packages = [
    pkgs.biome
    pkgs.nodejs
    pkgs.nil
        pkgs.surge-cli
  ];
}
