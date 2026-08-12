{
  ...
}:
{
  sops.secrets = {
    atuin-session = {
      path = "/Users/avy/.local/share/atuin/session";
      mode = "0444";
    };
    atuin-key = {
      path = "/Users/avy/.local/share/atuin/key";
      mode = "0444";
    };
    slack_user_id = { };
    context7_api_key = { };
    gh_mcp_token = { };
    chroma_mcp_token = { };
    icloud_email_password = { };
    soju_password = { };
    syncthing-guipass = {
      sopsFile = ../../secrets/services.yaml;
      key = "syncthing/guipass";
      path = "/Users/avy/.config/syncthing/guiPass";
      mode = "0400";
    };
  };
}
