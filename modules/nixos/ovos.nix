# OpenVoiceOS NixOS Module
#
# This module provides declarative configuration for OpenVoiceOS,
# including the message bus, TTS/STT services, and skills.
#
# TTS/STT models are managed through the flake's model registry (lib.models).
# Voice models are automatically fetched and configured when enabled.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.ovos;

  # Import OVOS packages directly so module doesn't depend on overlay
  ovosPackages = pkgs.callPackage ../../pkgs/ovos {};
in {
  options.services.ovos = {
    enable = mkEnableOption "OpenVoiceOS server";

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Host to bind services to";
    };

    port = mkOption {
      type = types.port;
      default = 8181;
      description = "Port for the messagebus WebSocket server";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for OVOS services";
    };

    logLevel = mkOption {
      type = types.enum ["DEBUG" "INFO" "WARNING" "ERROR"];
      default = "INFO";
      description = "Log level for OVOS services";
    };

    package = mkOption {
      type = types.package;
      default = ovosPackages.ovos-messagebus;
      defaultText = literalExpression "pkgs.ovosPackages.ovos-messagebus";
      description = "The ovos-messagebus package to use";
    };

    # TTS/Speech configuration
    speech = {
      enable = mkEnableOption "TTS speech service";

      backend = mkOption {
        type = types.str;
        default = "piper";
        description = "TTS backend to use (piper, etc.)";
      };

      voice = mkOption {
        type = types.str;
        default = "en_US-lessac-medium";
        description = "Piper voice name from model registry";
      };
    };

    # STT/Listener configuration
    listener = {
      enable = mkEnableOption "STT listener service";

      backend = mkOption {
        type = types.str;
        default = "faster-whisper";
        description = "STT backend to use (faster-whisper, etc.)";
      };

      model = mkOption {
        type = types.str;
        default = "base";
        description = "Whisper model name from model registry";
      };

      language = mkOption {
        type = types.str;
        default = "en";
        description = "Language code for speech recognition";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create ovos user and group
    users.users.ovos = {
      isSystemUser = true;
      group = "ovos";
      home = "/var/lib/ovos";
      createHome = true;
      description = "OpenVoiceOS system user";
    };

    users.groups.ovos = {};

    # Systemd service for ovos-messagebus
    systemd.services.ovos-messagebus = {
      description = "OpenVoiceOS Message Bus";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "ovos";
        Group = "ovos";
        ExecStart = "${cfg.package}/bin/ovos-messagebus";
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "ovos";
        ConfigurationDirectory = "ovos";
        RuntimeDirectory = "ovos";

        # Security hardening
        NoNewPrivileges = true;
        # PrivateTmp = true;  # Disabled - conflicts with memory-tempfile
        # ProtectSystem = "strict";  # Disabled - blocks /run/user access
        # ProtectHome = true;
        ReadWritePaths = [
          "/var/lib/ovos"
          "/run/ovos"
        ];
      };

      environment = {
        MYCROFT_SYSTEM_CONFIG = "/etc/ovos/mycroft.conf";
        OVOS_LOG_LEVEL = cfg.logLevel;
        XDG_RUNTIME_DIR = "/run/ovos";
        XDG_CONFIG_HOME = "/var/lib/ovos/.config";
        HOME = "/var/lib/ovos";
        TMPDIR = "/var/lib/ovos/tmp";
      };

      preStart = let
        ttsConfig =
          if cfg.speech.enable
          then ''
            "tts": {
              "module": "${cfg.speech.backend}",
              "piper": {
                "voice": "${cfg.speech.voice}"
              }
            },''
          else "";
        sttConfig =
          if cfg.listener.enable
          then ''
            "stt": {
              "module": "${cfg.listener.backend}",
              "faster_whisper": {
                "model": "${cfg.listener.model}",
                "lang": "${cfg.listener.language}"
              }
            },''
          else "";
      in ''
        # Create temp directory for combo-lock
        mkdir -p /var/lib/ovos/tmp
        chown ovos:ovos /var/lib/ovos/tmp

        # Create basic configuration if it doesn't exist
        mkdir -p /etc/ovos
        if [ ! -f /etc/ovos/mycroft.conf ]; then
          cat > /etc/ovos/mycroft.conf <<EOF
        {
          "websocket": {
            "host": "${cfg.host}",
            "port": ${toString cfg.port},
            "route": "/core",
            "ssl": false
          },
          ${ttsConfig}
          ${sttConfig}
          "log_level": "${cfg.logLevel}"
        }
        EOF
          chown ovos:ovos /etc/ovos/mycroft.conf
        fi
      '';
    };

    # Create runtime directory for ovos user (memory-tempfile expects /run/user/{uid})
    systemd.tmpfiles.rules = [
      "d /run/user/${toString config.users.users.ovos.uid} 0700 ovos ovos -"
    ];

    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
    };
  };

  meta = {
    maintainers = [];
  };
}
