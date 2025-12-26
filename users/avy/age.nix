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
    };
  };
}
