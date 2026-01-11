{
  pkgs,
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "zmx";
  version = "0.2.0";

  src = fetchurl {
    url =
      if stdenv.isLinux
      then
        (
          if stdenv.isAarch64
          then "https://zmx.sh/a/zmx-${version}-linux-aarch64.tar.gz"
          else "https://zmx.sh/a/zmx-${version}-linux-x86_64.tar.gz"
        )
      else if stdenv.isDarwin
      then
        (
          if stdenv.isAarch64
          then "https://zmx.sh/a/zmx-${version}-macos-aarch64.tar.gz"
          else "https://zmx.sh/a/zmx-${version}-macos-x86_64.tar.gz"
        )
      else throw "Unsupported platform";

    hash =
      if stdenv.isLinux && stdenv.isAarch64
      then "sha256-cMGo+Af0VRY3c2EoNzVZFU53Kz5wKL8zsSSXIOtZVU8="
      else if stdenv.isLinux
      then "sha256-Zmqs/Y3be2z9KMuSwyTLZWKbIInzHgoC9Bm0S2jv3XI="
      else if stdenv.isDarwin && stdenv.isAarch64
      then "sha256-nGjCLm4hZ3p4a/4LJJuyTc11uqXWgXBQqM+/4HxAh7Q="
      else "sha256-0epjoQhUSBYlE0L7Ubwn/sJF61+4BbxeaRx6EY/SklE=";
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp zmx $out/bin/
    chmod +x $out/bin/zmx
    runHook postInstall
  '';

  meta = with lib; {
    description = "Session persistence for terminal processes";
    homepage = "https://zmx.sh";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
