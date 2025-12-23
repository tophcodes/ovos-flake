# OpenVoiceOS NixOS Flake Design

**Date:** 2025-12-19
**Status:** Approved

## Overview

A standalone NixOS flake (`ovos-flake`) that provides:
- NixOS module for OpenVoiceOS server (system-wide, network-accessible)
- Home-manager module for OVOS client (system integration with hotkeys, notifications, GUI)
- Native Nix packages for all OVOS components (no Docker)
- Declarative model management for TTS/TTS models

## Architecture

### Core Design: Core + Plugins

The architecture follows a core + plugins pattern:
- **Core:** Message bus (required when OVOS is enabled)
- **Plugins:** Skills, audio, listener (STT), speech (TTS) - each independently toggleable

All components run as separate systemd services under a shared `ovos` user, with the messagebus as the central communication hub.

### Deployment Model

- **Server:** System-wide NixOS service, network-accessible with authentication
- **Client:** Home-manager configuration for local interaction
- **Focus:** Server mode without wake word detection (clients handle wake word)

## Project Structure

```
ovos-flake/
  flake.nix
  flake.lock

  modules/
    nixos/
      ovos.nix              # Main NixOS module
      ovos/
        messagebus.nix      # Core messagebus service
        skills.nix          # Skills service plugin
        audio.nix           # Audio output plugin
        listener.nix        # STT/listener plugin
        speech.nix          # TTS/speech plugin
        common.nix          # Shared utilities and config generation

    home-manager/
      ovos-client.nix       # Client integration module

  pkgs/
    ovos/
      default.nix           # All OVOS packages
      messagebus.nix
      core.nix
      audio.nix
      dinkum-listener.nix
      tts-server.nix
      piper.nix
      faster-whisper.nix

    ovos-skills/
      default.nix           # Skill registry
      weather.nix
      timer.nix
      ...

  lib/
    default.nix             # Helper functions
    models.nix              # Model registry

  tests/
    basic.nix               # NixOS VM tests

  README.md
  LICENSE
```

## NixOS Module Configuration

### Basic Structure

```nix
services.ovos = {
  enable = mkEnableOption "OpenVoiceOS server";

  host = mkOption {
    type = types.str;
    default = "0.0.0.0";
    description = "Host to bind services to";
  };

  openFirewall = mkOption {
    type = types.bool;
    default = false;
    description = "Open firewall ports for OVOS services";
  };

  logLevel = mkOption {
    type = types.enum [ "DEBUG" "INFO" "WARNING" "ERROR" ];
    default = "INFO";
  };

  authentication = {
    enable = mkEnableOption "API authentication";
    apiKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "API keys for authentication";
    };
    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing API keys (one per line)";
    };
  };

  plugins = {
    skills = {
      enable = mkEnableOption "Skills service";
      skills = mkOption {
        type = types.listOf (types.submodule {
          options = {
            package = mkOption { type = types.package; };
            settings = mkOption { type = types.attrs; default = {}; };
          };
        });
        default = [];
      };
    };

    audio = {
      enable = mkEnableOption "Audio service";
      backend = mkOption {
        type = types.str;
        default = "pulse";
      };
    };

    listener = {
      enable = mkEnableOption "STT listener service";
      backend = mkOption {
        type = types.str;
        default = "faster-whisper";
      };
      model = mkOption {
        type = types.str;
        default = "base";
        description = "Whisper model name from registry";
      };
      language = mkOption {
        type = types.str;
        default = "en";
      };
    };

    speech = {
      enable = mkEnableOption "TTS speech service";
      backend = mkOption {
        type = types.str;
        default = "piper";
      };
      voice = mkOption {
        type = types.str;
        default = "en_US-lessac-medium";
        description = "Piper voice name from registry";
      };
    };
  };
};
```

## Packaging Strategy

### Python Package Structure

All OVOS components packaged as native Nix derivations:

- **Services:** `buildPythonApplication` (messagebus, core, audio)
- **Libraries:** `buildPythonPackage` (skills, utilities)
- **Python version:** 3.11 or 3.12 (based on OVOS compatibility)

### Key Packaging Decisions

1. Handle OVOS plugin system using Python entry points
2. Patch hardcoded paths to use `/var/lib/ovos` and `/etc/ovos`
3. Pin dependencies explicitly
4. Include upstream tests (`doCheck = true`)

### Packages to Create

- `ovos-messagebus` - Core message bus
- `ovos-core` - Skills engine
- `ovos-audio` - Audio output service
- `ovos-dinkum-listener` - STT listener
- `ovos-tts-server` - TTS server
- `piper` - Piper TTS backend
- `faster-whisper` - Faster-Whisper STT backend
- Skills packages (weather, timer, etc.)

## Systemd Services

### Service Structure

Each component runs as a separate systemd service:

```nix
systemd.services = {
  ovos-messagebus = {
    description = "OpenVoiceOS Message Bus";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      User = "ovos";
      Group = "ovos";
      ExecStart = "${pkgs.ovos-messagebus}/bin/ovos-messagebus";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = "ovos";
      ConfigurationDirectory = "ovos";
      RuntimeDirectory = "ovos";
    };

    preStart = ''
      # Generate config files from Nix options
    '';
  };

  # Plugin services have dependencies on messagebus
  ovos-skills = {
    after = [ "ovos-messagebus.service" ];
    requires = [ "ovos-messagebus.service" ];
    # ...
  };
};
```

### User/Group Management

```nix
users.users.ovos = {
  isSystemUser = true;
  group = "ovos";
  home = "/var/lib/ovos";
  createHome = true;
};

users.groups.ovos = {};
```

**Directories:**
- `/var/lib/ovos` - State and data
- `/etc/ovos` - Generated configuration
- `/run/ovos` - Runtime files

## Authentication & Security

### Authentication Mechanism

API key-based authentication for messagebus and HTTP APIs:

- Bearer token authentication on websocket connections
- Keys stored in protected file or declared in config
- Middleware validates tokens before allowing connections

### Configuration Options

```nix
services.ovos.authentication = {
  enable = true;
  apiKeys = [ "key1" "key2" ];  # Less secure, in nix store
  apiKeyFile = "/run/secrets/ovos-api-keys";  # Recommended
};
```

### Network Security

- Services bind to `0.0.0.0` by default (configurable via `host` option)
- Optional firewall opening via `openFirewall` option
- No TLS in module - assume reverse proxy for HTTPS
- Compatible with secrets management (agenix, sops-nix)

**Ports:**
- 8181 - Message bus websocket
- 5002 - Skills API (if enabled)
- Additional ports per plugin

## Skills System

### Declarative Skill Configuration

Skills are explicitly declared in configuration:

```nix
services.ovos.plugins.skills = {
  enable = true;

  skills = [
    {
      package = pkgs.ovos-skill-weather;
      settings = {
        api_key = "...";
        units = "metric";
      };
    }
    {
      package = pkgs.ovos-skill-timer;
      settings = {};
    }
  ];
};
```

### Skill Loading Process

1. Each skill package provides Python package with entry points
2. Module generates `skills.json` config listing enabled skills
3. On service start, ovos-core loads declared skills only
4. Skill settings written to `/etc/ovos/skills/<skill-name>/settings.json`

### Skill Packaging Template

```nix
buildPythonPackage rec {
  pname = "ovos-skill-weather";
  version = "0.1.0";

  src = fetchFromGitHub { ... };

  propagatedBuildInputs = [ ovos-workshop requests ];

  postInstall = ''
    mkdir -p $out/share/ovos/skills
    cp -r ${pname} $out/share/ovos/skills/
  '';
}
```

### Built-in Skill Registry

Provide `pkgs.ovosSkills` set with common skills:
- `pkgs.ovosSkills.weather`
- `pkgs.ovosSkills.timer`
- `pkgs.ovosSkills.date-time`

Users can package custom skills following the same pattern.

## Model Management

### Model Registry

Centralized registry in `lib/models.nix`:

```nix
{
  piperVoices = {
    "en_US-lessac-medium" = {
      url = "https://huggingface.co/rhasspy/piper-voices/...";
      hash = "sha256-...";
      config = "https://huggingface.co/.../config.json";
      configHash = "sha256-...";
    };
    "en_US-amy-low" = { ... };
  };

  whisperModels = {
    "base" = {
      url = "https://huggingface.co/guillaumekln/faster-whisper-base";
      hash = "sha256-...";
      size = "74M";
    };
    "small" = { ... };
    "medium" = { ... };
  };
}
```

### Usage

```nix
services.ovos.plugins = {
  speech = {
    voice = "en_US-lessac-medium";  # References registry
  };
  listener = {
    model = "base";  # References registry
  };
};
```

### Implementation

1. Module looks up model in registry
2. Creates derivation with `fetchurl` and known hash
3. Symlinks model into `/var/lib/ovos/models/`
4. Generates config pointing to model path
5. Service reads config on startup

### Custom Models

```nix
services.ovos.plugins.speech = {
  customVoice = {
    path = /path/to/custom/model.onnx;
    config = /path/to/config.json;
  };
};
```

## Home-Manager Client Module

### Configuration Interface

```nix
programs.ovos-client = {
  enable = true;

  server = {
    host = "localhost";
    port = 8181;
    apiKey = "...";
    useTLS = false;
  };

  hotkey = {
    enable = true;
    binding = "<Super>space";
    action = "listen";
  };

  notifications = {
    enable = true;
    showResponses = true;
    timeout = 5000;
  };

  gui = {
    enable = true;
    showInTray = true;
  };
};
```

### Components

1. **CLI tool** (`ovos-client`):
   ```bash
   ovos-client "what time is it"
   ovos-client --listen
   ```

2. **GUI application**:
   - Python/GTK4 implementation
   - Microphone button for voice input
   - Text input field
   - Response display area
   - Connection status indicator

3. **System integration**:
   - Global hotkey service (window manager integration)
   - D-Bus service for notifications
   - System tray icon (optional)
   - Audio device integration

### Implementation

- Websocket client connecting to messagebus
- Systemd user services for background components
- Local audio capture and streaming to server

## Error Handling & Logging

### Logging Strategy

All services log to systemd journal:

```bash
journalctl -u ovos-messagebus -f
journalctl -u ovos-skills -f
```

Configurable log levels: DEBUG, INFO, WARNING, ERROR

### Error Handling

- Service failures trigger automatic restarts
- Failed model downloads fail at build time (fixed-output derivations)
- Missing dependencies caught during module evaluation
- Authentication failures logged with clear messages

### Health Checks

```nix
systemd.services.ovos-messagebus.serviceConfig = {
  ExecStartPost = "${pkgs.curl}/bin/curl -f http://localhost:8181/health";
  RestartSec = "5s";
};
```

## Testing Strategy

### NixOS VM Tests

```nix
nixosTests.ovos = makeTest {
  name = "ovos-basic";
  nodes.machine = { ... }: {
    services.ovos = {
      enable = true;
      plugins.skills.enable = true;
    };
  };

  testScript = ''
    machine.wait_for_unit("ovos-messagebus")
    machine.wait_for_open_port(8181)
    machine.succeed("ovos-client 'hello'")
  '';
};
```

### Test Coverage

1. **Basic functionality:**
   - Services start successfully
   - Messagebus connectivity
   - Authentication works

2. **Integration tests:**
   - Skill loading
   - TTS generation
   - Client-server communication

3. **Package tests:**
   - Upstream tests run during build
   - `doCheck = true` for all packages

## Flake Outputs

```nix
{
  outputs = { self, nixpkgs, ... }: {
    # NixOS module
    nixosModules.default = import ./modules/nixos/ovos.nix;
    nixosModules.ovos = self.nixosModules.default;

    # Home-manager module
    homeManagerModules.default = import ./modules/home-manager/ovos-client.nix;
    homeManagerModules.ovos-client = self.homeManagerModules.default;

    # Packages
    packages.x86_64-linux = {
      ovos-messagebus = ...;
      ovos-core = ...;
      ovos-audio = ...;
      ovos-dinkum-listener = ...;
      ovos-tts-server = ...;
      piper = ...;
      faster-whisper = ...;
    };

    # Overlay
    overlays.default = final: prev: {
      ovosPackages = self.packages.${prev.system};
    };

    # Tests
    checks.x86_64-linux = {
      basic = import ./tests/basic.nix;
    };
  };
}
```

## Usage Example

In consuming flake:

```nix
{
  inputs.ovos-flake.url = "github:yourusername/ovos-flake";

  outputs = { self, nixpkgs, ovos-flake, home-manager, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ovos-flake.nixosModules.default
        {
          services.ovos = {
            enable = true;
            openFirewall = true;

            authentication = {
              enable = true;
              apiKeyFile = "/run/secrets/ovos-api-keys";
            };

            plugins = {
              skills = {
                enable = true;
                skills = [
                  {
                    package = pkgs.ovosSkills.weather;
                    settings.units = "metric";
                  }
                ];
              };

              audio.enable = true;
              listener.enable = true;
              speech = {
                enable = true;
                voice = "en_US-lessac-medium";
              };
            };
          };
        }
      ];
    };

    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      modules = [
        ovos-flake.homeManagerModules.default
        {
          programs.ovos-client = {
            enable = true;
            server = {
              host = "localhost";
              apiKey = "...";
            };
            hotkey = {
              enable = true;
              binding = "<Super>space";
            };
          };
        }
      ];
    };
  };
}
```

## Implementation Priorities

### Phase 1: Core Infrastructure
1. Set up flake structure
2. Package ovos-messagebus
3. Create basic NixOS module
4. Get messagebus running as systemd service

### Phase 2: Essential Plugins
1. Package and integrate ovos-core (skills)
2. Package and integrate ovos-audio
3. Create skill packaging framework
4. Package 2-3 basic skills

### Phase 3: Voice Services
1. Package Piper TTS
2. Package Faster-Whisper STT
3. Implement model registry
4. Integrate TTS/STT services

### Phase 4: Security & Client
1. Implement authentication
2. Create home-manager client module
3. Build CLI client
4. Build GUI client

### Phase 5: Polish
1. Add comprehensive tests
2. Write documentation
3. Optimize performance
4. Community feedback integration

## Future Enhancements

- Additional TTS/STT backends
- More skills in registry
- Wake word detection support (optional)
- Multi-user support
- Prometheus metrics export
- Web UI for management
- Skill marketplace integration
