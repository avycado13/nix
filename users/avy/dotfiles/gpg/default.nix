{pkgs, ...}: {
  programs.gpg = {
    enable = true;
    mutableKeys = true;
  };
  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
  };
}
