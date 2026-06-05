let
  avy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPm9/uwsYQ2KrzaVcpulcDUKnBOCMCYogfC+D+TcrK7";
  users = [ avy ];

  piserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvLQS/x+Mjl0UN8I1z8wZiyoZnkVN4Zxj5pHrE9Ttfk";
  machines = [ piserver ];

  keys = users ++ machines;
in
{
  "miniflux_admin_password.age".publicKeys = keys;
  "atuin-session.age".publicKeys = keys;
  "atuin-key.age".publicKeys = keys;
  "slack_user_id.age".publicKeys = keys;
  "context7_api_key.age".publicKeys = keys;
  "gh_mcp_token.age".publicKeys = keys;
  "chroma_mcp_token.age".publicKeys = keys;
  "icloud_email_password.age".publicKeys = keys;
  "garnix-netrc.age".publicKeys = keys;
  "syncthing.json.age".publicKeys = keys;
  "syncthing-guipass.age".publicKeys = keys;
}
