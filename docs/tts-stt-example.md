# TTS/STT Configuration Example

This document shows how to configure Text-to-Speech (TTS) and Speech-to-Text (STT) services in OVOS.

## Basic Configuration

```nix
{
  services.ovos = {
    enable = true;

    # TTS Configuration
    speech = {
      enable = true;
      backend = "piper";
      voice = "en_US-lessac-medium";  # From model registry
    };

    # STT Configuration
    listener = {
      enable = true;
      backend = "faster-whisper";
      model = "base";  # From model registry
      language = "en";
    };
  };
}
```

## Available Models

### Piper TTS Voices

The model registry includes the following Piper voices:

- `en_US-lessac-medium` - High-quality American English voice (medium quality)
- `en_US-amy-low` - American English voice (low quality, faster)

### Whisper STT Models

The model registry includes the following Faster-Whisper models:

- `tiny` / `tiny.en` - Fastest, lowest quality (~39M parameters)
- `base` / `base.en` - Good balance of speed and quality (~74M parameters)
- `small` / `small.en` - Better quality (~244M parameters)
- `medium` / `medium.en` - High quality (~769M parameters)
- `large-v2` / `large-v3` - Best quality (~1550M parameters)

Models ending in `.en` are English-only and slightly faster.

## Model Registry

Models are defined in the flake's `lib.models` registry. Piper voice models are automatically fetched from Hugging Face and cached in the Nix store. Whisper models are downloaded on-demand by faster-whisper.

## Configuration Details

The TTS/STT configuration is written to `/etc/ovos/mycroft.conf` in JSON format:

```json
{
  "tts": {
    "module": "piper",
    "piper": {
      "voice": "en_US-lessac-medium"
    }
  },
  "stt": {
    "module": "faster_whisper",
    "faster_whisper": {
      "model": "base",
      "lang": "en"
    }
  }
}
```

## Future Work

The following TTS/STT services will be added in future phases:
- `ovos-dinkum-listener` - STT listener daemon
- `ovos-tts-server` - TTS server daemon
- Additional voice and model plugins

For now, the module provides configuration options and generates appropriate config files for when these services are implemented.
