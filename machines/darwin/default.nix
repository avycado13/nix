{
  inputs,
  ...
}:
let
  helpers = import ../../flakeHelpers.nix inputs;
in
{
  nixpkgs = helpers.nixpkgsCfg;
  imports = [ ../../modules/nix/default.nix ];
}
