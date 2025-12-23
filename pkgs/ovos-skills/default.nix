{
  lib,
  python3,
  ovos-workshop,
}:
# Skill registry - collection of available OVOS skills
lib.makeScope python3.pkgs.newScope (self: let
  callPackage = self.callPackage;

  # Helper function to create skill packages
  # Standardizes the packaging pattern for OVOS skills
  buildOvosSkill = {
    pname,
    version,
    src,
    skillId ? pname,
    propagatedBuildInputs ? [],
    meta ? {},
    ...
  } @ args:
    python3.pkgs.buildPythonPackage (
      {
        inherit pname version src;
        format = "setuptools";

        propagatedBuildInputs =
          [
            ovos-workshop
          ]
          ++ propagatedBuildInputs;

        # Create dummy requirements files
        postUnpack = ''
          mkdir -p $sourceRoot/requirements 2>/dev/null || true
          touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
          touch $sourceRoot/requirements.txt 2>/dev/null || true
        '';

        # Install skill data files
        postInstall = ''
          mkdir -p $out/share/ovos/skills/${skillId}
          if [ -d ${pname} ]; then
            cp -r ${pname}/* $out/share/ovos/skills/${skillId}/ || true
          fi
        '';

        doCheck = false; # Skills typically don't have standalone tests

        meta = with lib;
          {
            platforms = platforms.linux;
            license = licenses.asl20;
            maintainers = [];
          }
          // meta;
      }
      // (builtins.removeAttrs args ["skillId" "meta"])
    );
in {
  # Export the helper function
  inherit buildOvosSkill;

  # Individual skill packages
  date-time = callPackage ./date-time.nix {};

  # Additional skills can be added here following the same pattern
  # Example: weather = callPackage ./weather.nix {};
})
