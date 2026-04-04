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
  version = "1.3.15";

  platformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;

  nativeHashes = {
    "darwin-arm64" = "19ib984j0rmr3p7myqq12fp6saax3zn7bjd7sm9d1qkimig63027";
    "darwin-x64" = "0n71k9ah4w3afqkccnpamg9b7nq4iwhrdqzwkprk4bnsynf1f687";
    "linux-x64" = "0wg9h21c50lvz26644zpvnkrfpl70qiryd307wdan7fwxg5736gf";
    "linux-arm64" = "0iarvh3nhmm19jwyvgm70m50mvsvmzvi7hqqdjm6n13a4s460zqj";
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
