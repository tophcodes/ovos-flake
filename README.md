# OpenVoiceOS NixOS Flake

A standalone NixOS flake providing native Nix packages and modules for [OpenVoiceOS](https://github.com/OpenVoiceOS) - the open-source voice assistant platform.

## Features

- 🎯 **Native Nix packages** - No Docker, pure Nix derivations for all components
- ⚙️ **Declarative configuration** - Configure your voice assistant entirely in Nix
- 🔊 **TTS/STT support** - Integrated Piper TTS and Faster-Whisper STT with model registry
- 🧩 **Skills framework** - Easy packaging and deployment of OVOS skills
- 🔒 **Security hardened** - Systemd service hardening and proper user isolation
- 📦 **Model management** - Declarative model fetching from Hugging Face

## Quick Start

### Installation

Add this flake to your configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    ovos.url = "github:tophcodes/ovos-flake";
  };

  outputs = { nixpkgs, home-manager, ovos, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        ovos.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.users.youruser = {
            imports = [ ovos.homeManagerModules.default ];
          };
        }
        ./configuration.nix
      ];
    };
  };
}
```

### Basic Configuration

**NixOS (message bus):**
```nix
{
  services.ovos = {
    enable = true;  # Starts messagebus on port 8181
  };
}
```

**Home Manager (TTS/STT services):**
```nix
{
  services.ovos.audio = {
    enable = true;  # TTS with Piper
  };
}
```

### Custom Voice

Configure TTS voice in NixOS, use in home-manager:

```nix
# NixOS
services.ovos.speech.voice = "en_US-amy-low";  # Faster voice

# Home Manager - audio service reads this from system config
services.ovos.audio.enable = true;
```

## Configuration Options

### NixOS Module (System)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable OVOS messagebus |
| `host` | string | `"0.0.0.0"` | Host to bind messagebus to |
| `port` | port | `8181` | Messagebus WebSocket port |
| `speech.backend` | string | `"piper"` | TTS backend |
| `speech.voice` | string | `"en_US-lessac-medium"` | Piper voice |
| `location.timezone` | string | `"America/Chicago"` | Timezone |

### Home Manager Module (User Services)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `audio.enable` | bool | `false` | Enable TTS audio service |
| `audio.logLevel` | enum | `"INFO"` | Log level |
| `messagebusHost` | string | `"127.0.0.1"` | Messagebus host |
| `messagebusPort` | port | `8181` | Messagebus port |

## Available Packages

All packages are available in the `packages.<system>` flake output:

### Core Packages

- `ovos-messagebus` - Core message bus service
- `ovos-bus-client` - Message bus client library
- `ovos-config` - Configuration management
- `ovos-utils` - Utility library
- `ovos-plugin-manager` - Plugin loading system
- `ovos-workshop` - Skill framework base classes
- `ovos-core` - Skills engine and intent service
- `ovos-audio` - Audio output service

### Skills

- `ovos-skill-date-time` - Date, time, and day of week skill

### Usage

Build a package directly:

```bash
nix build github:tophcodes/ovos-flake#ovos-messagebus
```

Use in your own derivations:

```nix
{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    pkgs.ovosPackages.ovos-core
  ];
}
```

## Model Registry

The flake includes a declarative model registry for TTS and STT models at `lib.models`.

### Piper TTS Voices

Pre-configured voices fetched from Hugging Face:

| Voice | Quality | Description |
|-------|---------|-------------|
| `en_US-lessac-medium` | Medium | High-quality American English voice |
| `en_US-amy-low` | Low | Fast American English voice |

### Whisper STT Models

Supported Faster-Whisper models:

| Model | Parameters | Speed | Languages |
|-------|------------|-------|-----------|
| `tiny` / `tiny.en` | ~39M | Fastest | Multilingual / English-only |
| `base` / `base.en` | ~74M | Fast | Multilingual / English-only |
| `small` / `small.en` | ~244M | Moderate | Multilingual / English-only |
| `medium` / `medium.en` | ~769M | Slow | Multilingual / English-only |
| `large-v2` / `large-v3` | ~1550M | Slowest | Multilingual |

Models ending in `.en` are English-only and slightly faster.

### Accessing the Registry

```nix
# In your flake
let
  models = inputs.ovos.lib.models;
in {
  # Access a specific voice
  myVoice = models.piperVoices."en_US-lessac-medium";

  # List all voices
  allVoices = builtins.attrNames models.piperVoices;
}
```

## Skills Framework

The flake provides a `buildOvosSkill` helper for packaging OVOS skills.

### Creating a Skill Package

Create a file in `pkgs/ovos-skills/myskill.nix`:

```nix
{
  fetchFromGitHub,
  buildOvosSkill,
  requests,  # Additional dependencies
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

  skillId = "weather.openvoiceos";

  propagatedBuildInputs = [ requests ];

  meta = {
    description = "Weather skill for OpenVoiceOS";
    homepage = "https://github.com/OpenVoiceOS/skill-weather";
  };
}
```

Add to `pkgs/ovos-skills/default.nix`:

```nix
{
  # ... existing skills
  weather = callPackage ./weather.nix {};
}
```

The skill will be automatically exposed as `ovos-skill-weather` in the flake packages.

### What `buildOvosSkill` Does

- Automatically includes `ovos-workshop` dependency
- Creates dummy requirements files (OVOS packages expect these)
- Installs skill data to `/nix/store/.../share/ovos/skills/`
- Sets reasonable defaults for metadata
- Disables checks (skills typically don't have standalone tests)

## Advanced Examples

### Development Setup

**NixOS:**
```nix
{
  services.ovos = {
    enable = true;
    host = "127.0.0.1";  # Local only
    logLevel = "DEBUG";
  };
}
```

**Home Manager:**
```nix
{
  services.ovos.audio = {
    enable = true;
    logLevel = "DEBUG";
  };
}
```

### Using the Overlay

Apply the overlay to get OVOS packages in your `pkgs`:

```nix
{
  nixpkgs.overlays = [
    inputs.ovos.overlays.default
  ];

  # Now available as pkgs.ovosPackages.*
  environment.systemPackages = [
    pkgs.ovosPackages.ovos-core
  ];
}
```

## Service Management

### Systemd Commands

**System services:**
```bash
systemctl status ovos-messagebus
journalctl -u ovos-messagebus -f
```

**User services:**
```bash
systemctl --user status ovos-audio
journalctl --user -u ovos-audio -f
```

### File Locations

- **System config**: `/etc/mycroft/mycroft.conf`
- **System state**: `/var/lib/ovos/`
- **User config**: `~/.config/mycroft/mycroft.conf`

## Development

### Building Locally

```bash
# Build all packages
nix build .#ovos-messagebus
nix build .#ovos-core

# Run checks
nix flake check

# Format code
nix fmt

# Enter dev shell
nix develop
```

### Running Tests

```bash
# Run VM integration test
nix build .#checks.x86_64-linux.basic
```

### Adding a New Package

1. Create package file in `pkgs/ovos/mypackage.nix`
2. Add to `pkgs/ovos/default.nix` in the scope
3. Export in `flake.nix` packages output
4. Test build: `nix build .#mypackage`

## Project Status

✅ **Phase 1: Core Infrastructure** - Complete
✅ **Phase 2: Essential Plugins** - Complete
✅ **Phase 3: Voice Services** - Complete
✅ **Phase 4: Home Manager Module** - Complete
🚧 **Phase 5: STT/Listener** - Planned

### Current Components

- ✅ NixOS module (messagebus)
- ✅ Home Manager module (audio service)
- ✅ Piper TTS plugin with voice registry
- ✅ Core packages and plugin system
- ✅ Skills framework (buildOvosSkill)
- ⏳ STT listener service (future)
- ⏳ Skills service (future)

## Architecture

```
┌─────────────────┐
│   NixOS Module  │  Declarative configuration
└────────┬────────┘
         │
    ┌────▼────┐
    │ Message │  WebSocket server (port 8181)
    │   Bus   │  Core communication hub
    └────┬────┘
         │
    ┌────┼────┐
    │    │    │
┌───▼┐ ┌─▼──┐ ┌▼────┐
│Core│ │Audio│ │Skills│  Services communicate via bus
│    │ │     │ │      │
└─┬──┘ └──┬──┘ └───┬──┘
  │       │        │
  │   ┌───▼────┐   │
  │   │  TTS   │   │  Piper voices (model registry)
  │   │ Plugin │   │
  │   └────────┘   │
  │                │
  └────────┬───────┘
           │
      ┌────▼─────┐
      │  Skills  │  Extensible via buildOvosSkill
      └──────────┘
```

## Troubleshooting

### Service won't start

Check logs:
```bash
journalctl -u ovos-messagebus -n 50
```

Verify configuration:
```bash
cat /etc/ovos/mycroft.conf
```

### Port already in use

Change the port in configuration:
```nix
services.ovos.port = 8182;
```

### Model download fails

Models are fetched at build time. If you get hash mismatches, the model may have been updated. Please file an issue.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow the existing code style (use `nix fmt`)
4. Add tests if applicable
5. Submit a pull request

### Adding Models to Registry

To add a new Piper voice:

1. Get the model URL from [Hugging Face](https://huggingface.co/rhasspy/piper-voices)
2. Fetch with `nix-prefetch-url <url>`
3. Convert hash: `nix hash convert --hash-algo sha256 --to sri <hash>`
4. Add to `lib/models.nix`

## Resources

- [OpenVoiceOS Documentation](https://openvoiceos.github.io/ovos-technical-manual/)
- [OVOS GitHub Organization](https://github.com/OpenVoiceOS)
- [Piper TTS](https://github.com/rhasspy/piper)
- [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper)
- [Nix Flakes Manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)

## License

Apache-2.0

## Acknowledgments

- OpenVoiceOS team for the excellent voice assistant platform
- Rhasspy project for Piper TTS
- SYSTRAN for Faster-Whisper
- NixOS community for the packaging ecosystem

---

**Note:** This project was built with the assistance of generative AI (Claude Code). While the code has been reviewed and tested, please report any issues you encounter.
