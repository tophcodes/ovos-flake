{
  lib,
  pkgs,
}:
# Helper library for OVOS flake
{
  # Import the model registry
  models = import ./models.nix {
    inherit lib;
    inherit (pkgs) fetchurl stdenv;
  };
}
