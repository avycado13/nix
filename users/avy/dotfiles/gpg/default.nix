{pkgs, ...}: {
  programs.gpg = {
    enable = true;
    mutableKeys = true;
  };
}
