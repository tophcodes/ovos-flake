{
  lib,
  fetchurl,
  stdenv,
}:
# Model registry for OVOS TTS/STT models
# Provides centralized, declarative model management
{
  # Piper TTS voice models
  # Each voice entry includes the ONNX model and its configuration
  piperVoices = {
    "en_US-lessac-medium" = {
      model = fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx";
        hash = "sha256-Xv4J5pkCGHgnr2RuGm6dJp3udp+Yd9F7FrG0buqvAZ8=";
      };
      config = fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json";
        hash = "sha256-7+GcQXvtBV8taZCCSMa6ZQ+hNbyGiw5quz2hgdq2kKA=";
      };
      description = "High-quality American English voice (medium quality)";
    };

    "en_US-amy-low" = {
      model = fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/low/en_US-amy-low.onnx";
        hash = "sha256-pakau33g8QQ1iiWt7UgN2s8f8HYohjJYhuxAai6GqrM=";
      };
      config = fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/low/en_US-amy-low.onnx.json";
        hash = "sha256-IlCppgW43DWhFnF/rcUFZpXdgJ40oV0C9yoPUtU9Prs=";
      };
      description = "American English voice (low quality, faster)";
    };
  };

  # Faster-Whisper STT models
  # These models are automatically downloaded from Hugging Face by faster-whisper
  # We just provide metadata and model names for validation
  whisperModels = {
    "tiny" = {
      repo = "Systran/faster-whisper-tiny";
      description = "Tiny model (~39M parameters, fastest)";
      languages = "multilingual";
    };

    "tiny.en" = {
      repo = "Systran/faster-whisper-tiny.en";
      description = "Tiny English-only model (~39M parameters)";
      languages = "en";
    };

    "base" = {
      repo = "Systran/faster-whisper-base";
      description = "Base model (~74M parameters, good balance)";
      languages = "multilingual";
    };

    "base.en" = {
      repo = "Systran/faster-whisper-base.en";
      description = "Base English-only model (~74M parameters)";
      languages = "en";
    };

    "small" = {
      repo = "Systran/faster-whisper-small";
      description = "Small model (~244M parameters, better quality)";
      languages = "multilingual";
    };

    "small.en" = {
      repo = "Systran/faster-whisper-small.en";
      description = "Small English-only model (~244M parameters)";
      languages = "en";
    };

    "medium" = {
      repo = "Systran/faster-whisper-medium";
      description = "Medium model (~769M parameters, high quality)";
      languages = "multilingual";
    };

    "medium.en" = {
      repo = "Systran/faster-whisper-medium.en";
      description = "Medium English-only model (~769M parameters)";
      languages = "en";
    };

    "large-v2" = {
      repo = "Systran/faster-whisper-large-v2";
      description = "Large model v2 (~1550M parameters, best quality)";
      languages = "multilingual";
    };

    "large-v3" = {
      repo = "Systran/faster-whisper-large-v3";
      description = "Large model v3 (~1550M parameters, latest)";
      languages = "multilingual";
    };
  };

  # Helper function to create a Piper voice derivation
  # This combines the model and config into a single derivation
  mkPiperVoice = name: voice:
    stdenv.mkDerivation {
      pname = "piper-voice-${name}";
      version = "1.0";

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        mkdir -p $out
        ln -s ${voice.model} $out/model.onnx
        ln -s ${voice.config} $out/model.onnx.json
      '';

      meta = with lib; {
        description = voice.description;
        platforms = platforms.linux;
        license = licenses.cc0;
      };
    };
}
