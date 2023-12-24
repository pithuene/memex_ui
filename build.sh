#!/usr/bin/env bash

packages=$(nix flake show --json --quiet --quiet | jq '.packages' | jq -r 'map(keys) | add | join("\n")')
echo "$packages" | while read -r package; do
  echo "Building $package"
  nix build ".#$package"
done
