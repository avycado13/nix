let
  # Read the TOML file content as a string
  tomlString = builtins.readFile ~/.aerospace.toml;

  # Parse the TOML string into a Nix attribute set
  config = builtins.fromTOML tomlString;
in 
config