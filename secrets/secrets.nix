let
  personal_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPm9/uwsYQ2KrzaVcpulcDUKnBOCMCYogfC+D+TcrK7";
  keys = [personal_key];
in {
  "guest_accounts.json.age".publicKeys = keys;
}