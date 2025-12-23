{
  lib,
  python3,
}:
# Create a package set with circular dependency resolution
lib.makeScope python3.pkgs.newScope (
  self: let
    callPackage = self.callPackage;
  in {
    # Base dependencies (no OVOS dependencies)
    ovos-config = callPackage ./config.nix {};
    ovos-utils = callPackage ./utils.nix {};

    # Bus client (depends on config and utils)
    ovos-bus-client = callPackage ./bus-client.nix {};

    # Messagebus (depends on bus-client, utils, config)
    ovos-messagebus = callPackage ./messagebus.nix {};
  }
)
