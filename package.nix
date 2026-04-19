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
  version = "1.14.17";

  platformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;

  nativeHashes = {
    "darwin-arm64" = "1pg3ylmb672v1lka9v3zxy0v3srb9dd9a61yk78z8i6p7z687csv";
    "darwin-x64" = "15k9dzn0yzaapzx5gi05i1rs26ys2y2hm20n03am9iwpbi5iq0hs";
    "linux-x64" = "1mj1h3ikk1c9mz62d6p4wd905wm6ld9amhck9kp2hn8abr5vgrys";
    "linux-arm64" = "19fdm0my44qc89lchdzqbvf7wfb5pia1brac1qc7mprp5cywd8kk";
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
