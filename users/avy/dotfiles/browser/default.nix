{ pkgs }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.nur.forkprince.helium-nightly;

  };
}
