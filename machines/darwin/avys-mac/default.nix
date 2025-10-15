{
  inputs,
  pkgs,
  ...
}: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    brews = ["openssl" "wget" "git-crypt" "docker" "docker-compose"];
    casks = ["arc" "visual-studio-code" "foks" "kicad" "android-studio" "tailscale-app"];
    masApps = {
      "Xcode" = 497799835;
    };
    # taps = [ "homebrew/bundle" ] ++ builtins.attrNames config.nix-homebrew.taps;
  };

  # System-level packages
  environment.systemPackages = [
    # Development tools
    pkgs.git
    pkgs.onefetch
    pkgs.neovim
    pkgs.curl
    pkgs.wget
    pkgs.comma
    pkgs.colima

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
    pkgs.ripgrep
    pkgs.duf
  ];

  # Security settings
  security = {
    pam.services.sudo_local.touchIdAuth = true;
  };

  # Network settings
  networking = {
    computerName = "Avyays MacBook Air";
    hostName = "Avys-Mac";
    localHostName = "Avys-Mac";
  };

  # Nix Darwin version
  system = {
    stateVersion = 5;
    primaryUser = "avy";
  };

  # User settings
  users.users.avy = {
    name = "avy";
    home = "/Users/avy";
    shell = pkgs.zsh;
  };
}
