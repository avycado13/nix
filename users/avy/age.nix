{
  config,
  pkgs,
  lib,
  ...
}: {
  age = {
    identityPaths = ["/Users/avy/.ssh/avy"];
    secrets = {
      atuin-session = {
        file = builtins.toString ../../secrets/atuin-session.age;
      };
      atuin-key = {
        file = builtins.toString ../../secrets/atuin-key.age;
      };
      slack_user_id = {
        file = builtins.toString ../../secrets/slack_user_id.age;
      };
    };
  };
}
