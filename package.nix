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
  version = "1.4.0";

  platformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;

  nativeHashes = {
    "darwin-arm64" = "199r6bqacy8zn471p8a1fiz0n93hcqhjiilz1cpn5fsij1aqx5my";
    "darwin-x64" = "034y3qpg10ni1jgyrghfp76sqmxnijq0py8rbxbyvk2vk6sb8apv";
    "linux-x64" = "1kzjxz237p4yhlc8abikp9wivg3y3k83ga4v2jq4jbalm84fn5si";
    "linux-arm64" = "18rvs2vmhvdbj1sz3h5z97w1n4ql76l10k1y2slps56q8znjhmrg";
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
