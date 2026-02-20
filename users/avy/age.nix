{
  ...
}:
{
  age = {
    identityPaths = [ "/Users/avy/.ssh/avy" ];
    secrets = {
      atuin-session = {
        file = builtins.toString ../../secrets/atuin-session.age;
        path = "/Users/avy/.local/share/atuin/session";
        mode = "0444";

      };
      atuin-key = {
        file = builtins.toString ../../secrets/atuin-key.age;
        path = "/Users/avy/.local/share/atuin/key";
        mode = "0444";
      };
      slack_user_id = {
        file = builtins.toString ../../secrets/slack_user_id.age;
      };
      context7_api_key = {
        file = builtins.toString ../../secrets/context7_api_key.age;
        
      };
      gh_mcp_token = {
        file = builtins.toString ../../secrets/gh_mcp_token.age;
      };
    };
  };
}
