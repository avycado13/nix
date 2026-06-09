{
  config,
  pkgs,
  ...
}:
let
  # Pick the right upstream package per platform.
  syncthingPackage = if pkgs.stdenv.isDarwin then pkgs.syncthing-macos else pkgs.syncthing;

in
{
  services.syncthing = {
    enable = true;
    package = syncthingPackage;
    overrideDevices = true;
    overrideFolders = true;
    guiAddress = "0.0.0.0:8384";
    guiCredentials = {
      username = "avy";
      passwordFile = config.sops.secrets.syncthing-guipass.path;
    };
    settings = {
      options.relaysEnabled = true;
      urAccepted = -1;
      devices = {
        "Avys-Mac" = {
          # Replace with the actual device ID from `syncthing --device-id`
          id = "ZU2VV6Q-KU2QH2C-Z6PELOK-7YXOH7B-D6PAZNY-WROV7VD-4CNJNBG-CSZ4EQP";
        };
        "pixel-3" = {
          # Replace with the actual device ID from the Syncthing app on the Pixel 3
          id = "XRQ5W4J-V3BJKXH-2NIAP4E-JRPWVGQ-GQ5EFKG-IRFYUGD-55F62F3-GETMOAI";
        };
      };

      folders = {
        "music" = {
          path = "${config.home.homeDirectory}/Music/Library";
          devices = [
            "Avys-Mac"
            "pixel-3"
          ];
        };
      };
    };
  };

}
