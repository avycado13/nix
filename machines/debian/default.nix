{
  config,
  pkgs,
  ...
}: {
  environment = {
    etc = {
      "foo.conf".text = ''
        launch_the_rockets = true
      '';
    };
    systemPackages = [
      # Development tools
      pkgs.git
      pkgs.onefetch
      pkgs.neovim
      pkgs.curl
      pkgs.wget
      pkgs.comma

      # System utilities
      pkgs.coreutils
      pkgs.htop
      pkgs.tree
      # misc stuff that everyone needs!
      pkgs.cowsay
      pkgs.file
      pkgs.which
      pkgs.gnused
      pkgs.gnutar
      pkgs.gawk
      pkgs.zstd
      pkgs.gnupg
      pkgs.duf
      pkgs.ffmpeg
    ];
  };
  config = {
    system-manager.allowAnyDistro = true;
  };
}
