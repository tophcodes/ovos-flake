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

    # Location configuration
    location = {
      city = mkOption {
        type = types.str;
        default = "Lawrence";
        description = "City name for location-based features";
      };

      state = mkOption {
        type = types.str;
        default = "Kansas";
        description = "State/region name";
      };

      country = mkOption {
        type = types.str;
        default = "USA";
        description = "Country name";
      };

      timezone = mkOption {
        type = types.str;
        default = "America/Chicago";
        example = "Europe/Berlin";
        description = "Timezone code (e.g., America/New_York, Europe/London)";
      };

      latitude = mkOption {
        type = types.float;
        default = 38.9717;
        description = "Latitude coordinate";
      };

      longitude = mkOption {
        type = types.float;
        default = -95.2353;
        description = "Longitude coordinate";
      };
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
        ];
      };

      environment = {
        # Config is available at /etc/mycroft/mycroft.conf (standard OVOS location)
        OVOS_LOG_LEVEL = cfg.logLevel;
        XDG_CONFIG_HOME = "${cfg.stateDir}/.config";
        XDG_DATA_HOME = "${cfg.stateDir}/.local/share";
        XDG_CACHE_HOME = "${cfg.stateDir}/.cache";
        HOME = cfg.stateDir;
        TMPDIR = "${cfg.stateDir}/tmp";
      };

      preStart = ''
        # Create XDG directories
        mkdir -p ${cfg.stateDir}/tmp
        mkdir -p ${cfg.stateDir}/.config
        mkdir -p ${cfg.stateDir}/.local/share
        mkdir -p ${cfg.stateDir}/.cache
        chown -R ${cfg.user}:${cfg.group} ${cfg.stateDir}
      '';
    };

    # Systemd service for ovos-audio (TTS)
    systemd.services.ovos-audio = mkIf cfg.speech.enable {
      description = "OpenVoiceOS Audio Service (TTS)";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "ovos-messagebus.service"];
      requires = ["ovos-messagebus.service"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${ovosPackages.ovos-audio}/bin/ovos-audio";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        ReadWritePaths = [
          cfg.stateDir
        ];
      };

      environment = {
        OVOS_LOG_LEVEL = cfg.logLevel;
        XDG_CONFIG_HOME = "${cfg.stateDir}/.config";
        XDG_DATA_HOME = "${cfg.stateDir}/.local/share";
        XDG_CACHE_HOME = "${cfg.stateDir}/.cache";
        HOME = cfg.stateDir;
        TMPDIR = "${cfg.stateDir}/tmp";
      };
    };

    # Create system-wide OVOS configuration
    # This makes the config available to all OVOS services and CLI tools
    environment.etc."mycroft/mycroft.conf" = let
      mycroftConfig = {
        websocket = {
          host = cfg.host;
          port = cfg.port;
          route = "/core";
          ssl = false;
        };
        location = {
          city = {
            code = cfg.location.city;
            name = cfg.location.city;
            state = {
              code = cfg.location.state;
              name = cfg.location.state;
              country = {
                code = cfg.location.country;
                name = cfg.location.country;
              };
            };
          };
          coordinate = {
            latitude = cfg.location.latitude;
            longitude = cfg.location.longitude;
          };
          timezone = {
            code = cfg.location.timezone;
            name = cfg.location.timezone;
          };
        };
        log_level = cfg.logLevel;
      } // lib.optionalAttrs cfg.speech.enable {
        tts = {
          module = cfg.speech.backend;
          piper = {
            voice = cfg.speech.voice;
          };
        };
      } // lib.optionalAttrs cfg.listener.enable {
        stt = {
          module = cfg.listener.backend;
          faster_whisper = {
            model = cfg.listener.model;
            lang = cfg.listener.language;
          };
        };
      };
    in {
      source = pkgs.writeText "mycroft.conf" (builtins.toJSON mycroftConfig);
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
    };
  };

  meta = {
    maintainers = [];
  };
}
