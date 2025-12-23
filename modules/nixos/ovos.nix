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

    user = mkOption {
      type = types.str;
      default = "ovos";
      description = "The user to run the server as";
    };

    group = mkOption {
      type = types.str;
      default = "ovos";
      description = "The group to run the server as";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/ovos";
      description = "Directory for OVOS state and data";
    };

    configDir = mkOption {
      type = types.str;
      default = "/etc/ovos";
      description = "Directory for OVOS configuration files";
    };

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
    users = {
      users.${cfg.user} = {
        isSystemUser = lib.mkDefault true;
        group = lib.mkDefault cfg.group;
        home = lib.mkDefault cfg.stateDir;
        createHome = lib.mkDefault true;
        description = lib.mkDefault "OpenVoiceOS system user";
      };

      groups.${cfg.group} = {};
    };

    # Systemd service for ovos-messagebus
    systemd.services.ovos-messagebus = {
      description = "OpenVoiceOS Message Bus";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/ovos-messagebus";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        # PrivateTmp = true;  # Disabled - conflicts with memory-tempfile
        # ProtectSystem = "strict";  # Disabled - blocks /run/user access
        # ProtectHome = true;
        ReadWritePaths = [
          cfg.stateDir
          cfg.configDir
        ];
      };

      environment = {
        MYCROFT_SYSTEM_CONFIG = "${cfg.configDir}/mycroft.conf";
        OVOS_LOG_LEVEL = cfg.logLevel;
        XDG_CONFIG_HOME = "${cfg.stateDir}/.config";
        HOME = cfg.stateDir;
        TMPDIR = "${cfg.stateDir}/tmp";
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
        mkdir -p ${cfg.stateDir}/tmp
        chown ${cfg.user}:${cfg.group} ${cfg.stateDir}/tmp

        # Create basic configuration if it doesn't exist
        mkdir -p ${cfg.configDir}
        if [ ! -f ${cfg.configDir}/mycroft.conf ]; then
          cat > ${cfg.configDir}/mycroft.conf <<EOF
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
          chown ${cfg.user}:${cfg.group} ${cfg.configDir}/mycroft.conf
        fi
      '';
    };

    # Create runtime directory for ovos user (memory-tempfile expects /run/user/{uid})
    systemd.tmpfiles.rules = [
      "d /run/user/${toString config.users.users.${cfg.user}.uid} 0700 ${cfg.user} ${cfg.group} -"
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
