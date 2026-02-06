let
  mkService = import ../../../lib/mkService.nix;
in
mkService {
  name = "indiko";
  description = "Indiko authentication service";
  defaultPort = 3000;
  runtime = "bun";
  entryPoint = "start";
  startCommand = null;
}
