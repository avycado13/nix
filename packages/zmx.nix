{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zmx";
  version = "0.4.1";

  src = fetchurl {
    url =
      if stdenv.isLinux then
        (
          if stdenv.isAarch64 then
            "https://zmx.sh/a/zmx-${version}-linux-aarch64.tar.gz"
          else
            "https://zmx.sh/a/zmx-${version}-linux-x86_64.tar.gz"
        )
      else if stdenv.isDarwin then
        (
          if stdenv.isAarch64 then
            "https://zmx.sh/a/zmx-${version}-macos-aarch64.tar.gz"
          else
            "https://zmx.sh/a/zmx-${version}-macos-x86_64.tar.gz"
        )
      else
        throw "Unsupported platform";

    hash =
      if stdenv.isLinux && stdenv.isAarch64 then
        "sha256-9TAOjfBmfUDkdN8lnAvPq5No2UBbY5GMpeScr+Jyx3Q="
      else if stdenv.isLinux then
        "sha256-fyfjbYmkGVre02piDR/L0NbylsWDEEV2JrrrUCubTjI="
      else if stdenv.isDarwin && stdenv.isAarch64 then
        "sha256-tGHgGoEkCKS5Pw+/YdI2ljFE0GgAVc6zY/Mk6Xt8/To="
      else
        "sha256-gxRROnHA8NUOheJCMu8IlvSlwynJvWqBkbCYSj4BOeE=";
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

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
