{ lib, ... }:
{
  # You can use lib.nixvim in your config
  fooOption = lib.nixvim.mkRaw "print('hello')";

  # Configure Nixvim without prefixing with `plugins.nixvim`
  # plugins.my-plugin.enable = true;
}
