{
  inputs,
  pkgs,
  ...
}: {
  virtualisation = {
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.dnsname.enable = true;
      defaultNetwork.settings.dns_enabled = true;
      dockerCompat = true;
    };
    containers.enable = true;
    oci-containers.backend = "podman";
    oci-containers.containers = {
    # container-name = {
    #   image = "container-image";
    #   autoStart = true;
    #   ports = [ "127.0.0.1:1234:1234" ];
    # };
  };
  };
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    #podman-compose # start group of containers for dev
  ];
}
