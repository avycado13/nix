{
  ...
}:
{
  networking.hostName = "gce";

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  programs.man.enable = false;

  # google-compute-image.nix only creates a /boot partition when EFI
  # booting is enabled (it isn't here), so /boot lives on the root
  # partition — nix-mineral's separate-partition hardening doesn't apply.
  nix-mineral.filesystems.normal."/boot".enable = false;

  system.stateVersion = "26.05";
}
