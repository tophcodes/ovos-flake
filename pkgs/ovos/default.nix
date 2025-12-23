{
  lib,
  python3,
}:
# Create a package set with circular dependency resolution
lib.makeScope python3.pkgs.newScope (
  self: let
    callPackage = self.callPackage;
  in {
    # Third-party dependencies not in nixpkgs or pinned versions
    kthread = callPackage ./kthread.nix {};
    pyee = callPackage ./pyee.nix {}; # Pin to 11.x for OVOS compatibility
    combo-lock = callPackage ./combo-lock.nix {};
    json-database = callPackage ./json-database.nix {};
    quebra-frases = callPackage ./quebra-frases.nix {};

    # Base dependencies (no OVOS dependencies)
    ovos-config = callPackage ./config.nix {};
    ovos-utils = callPackage ./utils.nix {};

    # Bus client (depends on config and utils)
    ovos-bus-client = callPackage ./bus-client.nix {};

    # Plugin manager (depends on config and utils)
    ovos-plugin-manager = callPackage ./plugin-manager.nix {};

    # Workshop (depends on bus-client, config, utils, plugin-manager)
    ovos-workshop = callPackage ./workshop.nix {};

    # Messagebus (depends on bus-client, utils, config)
    ovos-messagebus = callPackage ./messagebus.nix {};

    # Core (depends on most other packages)
    ovos-core = callPackage ./core.nix {};

    # Audio service (depends on utils, bus-client, config, plugin-manager)
    ovos-audio = callPackage ./audio.nix {};

    # TTS Plugins
    ovos-tts-plugin-piper = callPackage ./tts-plugin-piper.nix {};
  }
)
