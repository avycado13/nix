{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "lazycut";
  version = "0.3.3";

  src = fetchurl {
    url =
      if stdenv.isDarwin then
        (
          if stdenv.isAarch64 then
            "https://github.com/emin-ozata/lazycut/releases/download/v${version}/lazycut_${version}_darwin_arm64.tar.gz"
          else
            "https://github.com/emin-ozata/lazycut/releases/download/v${version}/lazycut_${version}_darwin_amd64.tar.gz"
        )
      else
        throw "Unsupported platform";

    hash =
      if stdenv.isDarwin && stdenv.isAarch64 then
        "sha256-GLmK+EvNYo9VHeZ0YWTse6ft5o2v5noBnoSBtaQbeew="
      else if stdenv.isDarwin then
        "sha256-zs8xQzsWzy0PVkewVpJMTsxebzwpltc48xbpH+o2LnQ=";
      else
        throw "Unsupported platform";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp lazycut $out/bin/
    chmod +x $out/bin/lazycut
    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal-based video trimming tool";
    homepage = "https://github.com/emin-ozata/lazycut";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "lazycut";
  };
}
