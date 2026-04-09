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
  version = "1.4.1";

  platformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;

  nativeHashes = {
    "darwin-arm64" = "1k344hnlmjya1d81a26msymd1sk142narp17j9d9wrpxbzfrd66n";
    "darwin-x64" = "1wz5j7vxbwxc1mg8pgzzh9pndj8hmn59sj68dnk8mplbfyg1x44y";
    "linux-x64" = "1hyn8qa6b1b7qyhzf3mai2ivb0s4gqrgh96qlp0lfs6hh0rh49vb";
    "linux-arm64" = "12ac3xxqrbysky2n6b4h6pr80pfx8px9f5iff94dvbsiyi3gw7q4";
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
