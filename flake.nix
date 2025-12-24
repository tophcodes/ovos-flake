{
  description = "OpenVoiceOS NixOS Flake - Native Nix packages and modules for OVOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    # Systems to support
    systems = ["x86_64-linux" "aarch64-linux"];
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
        ovosPackages = pkgs.callPackage ./pkgs/ovos {};
        ovosSkills = pkgs.callPackage ./pkgs/ovos-skills {
          ovos-workshop = ovosPackages.ovos-workshop;
        };
      in {
        # Packages
        packages =
          {
            inherit
              (ovosPackages)
              ovos-messagebus
              ovos-bus-client
              ovos-config
              ovos-utils
              ovos-plugin-manager
              ovos-workshop
              ovos-core
              ovos-audio
              ovos-tts-plugin-piper
              ;
            default = ovosPackages.ovos-messagebus;
          }
          // (nixpkgs.lib.mapAttrs' (name: value: nixpkgs.lib.nameValuePair "ovos-skill-${name}" value) (nixpkgs.lib.filterAttrs (n: v: nixpkgs.lib.isDerivation v) ovosSkills));

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            alejandra
            nix-tree
          ];
        };

        # Formatter
        formatter = pkgs.alejandra;

        # Checks/tests
        checks = {
          basic = pkgs.callPackage ./tests/basic.nix {inherit self;};
        };
      }
    )
    // {
      # NixOS module (system-independent)
      nixosModules.default = import ./modules/nixos/ovos.nix;
      nixosModules.ovos = self.nixosModules.default;

      # Home Manager module
      homeManagerModules.default = import ./modules/home-manager/ovos.nix;
      homeManagerModules.ovos = self.homeManagerModules.default;

      # Overlay
      overlays.default = final: prev: {
        ovosPackages = final.callPackage ./pkgs/ovos {};
      };

      # Library functions and model registry
      lib = import ./lib {
        lib = nixpkgs.lib;
        pkgs = import nixpkgs {system = "x86_64-linux";};
      };
    };
}
