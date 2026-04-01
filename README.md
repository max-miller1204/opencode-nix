# opencode-nix

Always up-to-date Nix package for [OpenCode](https://github.com/anomalyco/opencode) - open source AI coding agent in your terminal.

**Automatically updated hourly** to keep you on the latest OpenCode release.

**Uses native pre-built binaries** - no Node.js dependency required.

## Quick Start

```bash
# Run directly
nix run github:max-miller1204/opencode-nix

# Install to profile
nix profile install github:max-miller1204/opencode-nix
```

## Using with Flakes

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode-nix.url = "github:max-miller1204/opencode-nix";
  };

  outputs = { self, nixpkgs, opencode-nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ opencode-nix.packages.${system}.default ];
      };
    };
}
```

## Development

```bash
git clone https://github.com/max-miller1204/opencode-nix
cd opencode-nix

nix build
./result/bin/opencode --version
```

## Automated Updates

This repository runs an hourly GitHub Actions workflow that:

1. Checks latest OpenCode release from `anomalyco/opencode`
2. Updates `version` and per-platform hashes in `package.nix`
3. Creates a PR and enables auto-merge
4. Verifies builds in CI on Linux and macOS

## Manual Updates

```bash
# Check if an update is available
./scripts/update.sh --check

# Update to latest release
./scripts/update.sh

# Update to a specific version
./scripts/update.sh --version 1.3.13
```

## License

This Nix packaging is licensed under MIT. OpenCode itself is licensed by its upstream project.
