{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, glibc
, gcc-unwrapped
, gnutar
, gzip
, unzip
}:

let
  version = "1.4.11";

  platformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;

  nativeHashes = {
    "darwin-arm64" = "18gx6cxznim6h582lx33xcd6y1z3xd36jk17wavclsb81j5x9r11";
    "darwin-x64" = "124zczjh7kl1kcl2sqrvi2rj5skgwypz39ajxbxzki72ah0y7va0";
    "linux-x64" = "137nv6dyzn47jkqxa4al9s60kaj64nprn0xz5fjznjixpsg85sm4";
    "linux-arm64" = "1sq60ns10isxnd2p65sq2yv6cv7la9nqkp1lm5cw7saxjianp7a3";
  };

  extension = if stdenv.hostPlatform.isDarwin then "zip" else "tar.gz";
  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-${platform}.${extension}";
    sha256 = nativeHashes.${platform};
  };
in
assert platform != null ||
  throw "Unsupported platform: ${stdenv.hostPlatform.system}. Supported: aarch64-darwin, x86_64-darwin, x86_64-linux, aarch64-linux";

stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [ gnutar gzip unzip ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glibc
    gcc-unwrapped.lib
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p build
    ${if stdenv.hostPlatform.isDarwin then "unzip -qo ${src} -d build" else "tar -xzf ${src} -C build"}
    chmod u+w,+x build/opencode
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp build/opencode $out/bin/opencode
    chmod +x $out/bin/opencode
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode CLI - AI coding agent in your terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
    mainProgram = "opencode";
  };
}
