{ config, ... }:
{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age = {
    keyFile = "${config.users.users.avy.home}/.config/sops/age/keys.txt";
    sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/Users/avy/.ssh/avy"
    ];
  };
}
