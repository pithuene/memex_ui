.PHONY: nix-build
nix-build:
	nix-build -E "with (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz) {}); callPackage ./default.nix {}"

