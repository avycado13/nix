{
  ...
}:
{
  age = {
    identityPaths = [ "/Users/avy/.ssh/avy" ];
    secrets = {
      atuin-session = {
        file = ../../secrets/atuin-session.age;
        path = "/Users/avy/.local/share/atuin/session";
        mode = "0444";
      };
      atuin-key = {
        file = ../../secrets/atuin-key.age;
        path = "/Users/avy/.local/share/atuin/key";
        mode = "0444";
      };
      slack_user_id = {
        file = ../../secrets/slack_user_id.age;
      };
      context7_api_key = {
        file = ../../secrets/context7_api_key.age;
      };
      gh_mcp_token = {
        file = ../../secrets/gh_mcp_token.age;
      };
      chroma_mcp_token = {
        file = ../../secrets/chroma_mcp_token.age;
      };
      icloud_email_password = {
        file = ../../secrets/icloud_email_password.age;
      };
      syncthing = {
        file = ../../secrets/syncthing.json.age;
        path = "/Users/avy/.config/syncthing/secrets.json";
        mode = "0400";
      };
      syncthing-guipass = {
        file = ../../secrets/syncthing-guipass.age;
        path = "/Users/avy/.config/syncthing/guiPass";
        mode = "0400";
      };

    };
  };
}
