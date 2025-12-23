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

Add this flake to your NixOS configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ovos-flake.url = "github:yourusername/ovos-flake";
  };

  outputs = { self, nixpkgs, ovos-flake }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ovos-flake.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Basic Configuration

Enable OpenVoiceOS with default settings:

```nix
{
  services.elements.ovos = {
    enable = true;
    openFirewall = true;  # Allow network access to message bus
  };
}
```

This starts the OVOS message bus on port 8181 (WebSocket).

### With TTS and STT

Enable voice services with specific models:

```nix
{
  services.elements.ovos = {
    enable = true;
    openFirewall = true;

    # Text-to-Speech configuration
    speech = {
      enable = true;
      backend = "piper";
      voice = "en_US-lessac-medium";  # High-quality voice
    };

    # Speech-to-Text configuration
    listener = {
      enable = true;
      backend = "faster-whisper";
      model = "base";      # Good balance of speed/quality
      language = "en";
    };
  };
}
```

## Configuration Options

### Core Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable OpenVoiceOS server |
| `host` | string | `"0.0.0.0"` | Host to bind services to |
| `port` | port | `8181` | Port for the messagebus WebSocket server |
| `openFirewall` | bool | `false` | Open firewall ports for OVOS services |
| `logLevel` | enum | `"INFO"` | Log level: DEBUG, INFO, WARNING, ERROR |
| `package` | package | `pkgs.ovosPackages.ovos-messagebus` | The ovos-messagebus package to use |

### Speech/TTS Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `speech.enable` | bool | `false` | Enable TTS speech service |
| `speech.backend` | string | `"piper"` | TTS backend to use |
| `speech.voice` | string | `"en_US-lessac-medium"` | Voice name from model registry |

### Listener/STT Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `listener.enable` | bool | `false` | Enable STT listener service |
| `listener.backend` | string | `"faster-whisper"` | STT backend to use |
| `listener.model` | string | `"base"` | Model name from model registry |
| `listener.language` | string | `"en"` | Language code for speech recognition |

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
nix build github:yourusername/ovos-flake#ovos-messagebus
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
  ovosFLake = inputs.ovos-flake;
  models = ovosFlake.lib.models;
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

### Production Server

```nix
{
  services.elements.ovos = {
    enable = true;
    host = "0.0.0.0";
    port = 8181;
    openFirewall = true;
    logLevel = "INFO";

    speech = {
      enable = true;
      voice = "en_US-lessac-medium";
    };

    listener = {
      enable = true;
      model = "small";  # Better quality for production
      language = "en";
    };
  };

  # Optional: restrict network access
  networking.firewall.interfaces."eth0".allowedTCPPorts = [ 8181 ];
}
```

### Development Setup

```nix
{
  services.elements.ovos = {
    enable = true;
    host = "127.0.0.1";  # Local only
    logLevel = "DEBUG";

    speech.enable = true;
    listener = {
      enable = true;
      model = "tiny";  # Fast for testing
    };
  };
}
```

### Using the Overlay

Apply the overlay to get OVOS packages in your `pkgs`:

```nix
{
  nixpkgs.overlays = [
    inputs.ovos-flake.overlays.default
  ];

  # Now available as pkgs.ovosPackages.*
  environment.systemPackages = [
    pkgs.ovosPackages.ovos-core
  ];
}
```

## Service Management

### Systemd Commands

```bash
# Check service status
systemctl status ovos-messagebus

# View logs
journalctl -u ovos-messagebus -f

# Restart service
systemctl restart ovos-messagebus
```

### File Locations

- **Configuration**: `/etc/ovos/mycroft.conf`
- **State/Data**: `/var/lib/ovos/`
- **Runtime**: `/run/ovos/`
- **User**: `ovos:ovos`

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
🚧 **Phase 4: Security & Client** - Planned
🚧 **Phase 5: Polish** - Planned

### Current Components

- ✅ Message bus service
- ✅ Core packages (config, utils, bus-client)
- ✅ Plugin manager and workshop
- ✅ Skills engine (ovos-core)
- ✅ Audio output service
- ✅ Skills framework
- ✅ Model registry
- ✅ TTS/STT configuration
- ⏳ Listener daemon (future)
- ⏳ TTS server daemon (future)
- ⏳ Authentication (future)
- ⏳ Home-manager client (future)

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
services.elements.ovos.port = 8182;
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
