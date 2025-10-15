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
      pkgs.ripgrep
      pkgs.fd
      pkgs.hello
    ];
  };
  config = {
    system-manager.allowAnyDistro = true;
  };
}
