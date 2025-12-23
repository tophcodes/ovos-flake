# OVOS Skills Packaging Framework

This directory contains the skill packaging framework and individual skill packages for OpenVoiceOS.

## Structure

- `default.nix` - Skill registry and `buildOvosSkill` helper function
- Individual skill files (e.g., `weather.nix`, `timer.nix`)

## Using the Framework

### Creating a New Skill Package

The `buildOvosSkill` function standardizes skill packaging:

```nix
{
  fetchFromGitHub,
  buildOvosSkill,
  # Additional Python dependencies
  requests,
}:

buildOvosSkill rec {
  pname = "ovos-skill-weather";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "OpenVoiceOS";
    repo = "skill-weather";
    rev = "v${version}";
    hash = "sha256-...";
  };

  # Optional: Override skill ID (defaults to pname)
  skillId = "weather.openvoiceos";

  # Additional dependencies beyond ovos-workshop
  propagatedBuildInputs = [ requests ];

  meta = {
    description = "Weather skill for OpenVoiceOS";
    homepage = "https://github.com/OpenVoiceOS/skill-weather";
  };
}
```

### Features

The `buildOvosSkill` helper automatically:
- Includes `ovos-workshop` as a dependency
- Creates dummy requirements files to avoid setup.py issues
- Installs skill data to `/nix/store/.../share/ovos/skills/`
- Sets reasonable defaults for metadata
- Disables checks (skills don't typically have standalone tests)

## Adding Skills to the Registry

1. Create a `.nix` file in this directory for your skill
2. Add it to `default.nix`:

```nix
{
  weather = callPackage ./weather.nix {};
  timer = callPackage ./timer.nix {};
}
```

3. Skills will be available as `pkgs.ovosSkills.weather`, etc.
