# OpenVoiceOS Home Manager Module
#
# Provides user services for OVOS client components (audio, listener)
# that connect to the system-wide messagebus.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.ovos;
in {
  options.services.ovos = {
    messagebusHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host where the OVOS messagebus is running";
    };

    messagebusPort = mkOption {
      type = types.port;
      default = 8181;
      description = "Port where the OVOS messagebus is running";
    };

    # Audio/TTS service
    audio = {
      enable = mkEnableOption "OVOS audio service (TTS)";

      package = mkOption {
        type = types.package;
        default = pkgs.ovosPackages.ovos-audio;
        defaultText = literalExpression "pkgs.ovosPackages.ovos-audio";
        description = "The ovos-audio package to use";
      };

      logLevel = mkOption {
        type = types.enum ["DEBUG" "INFO" "WARNING" "ERROR"];
        default = "INFO";
        description = "Log level for audio service";
      };
    };

    # Listener/STT service (future)
    listener = {
      enable = mkEnableOption "OVOS listener service (STT)";

      logLevel = mkOption {
        type = types.enum ["DEBUG" "INFO" "WARNING" "ERROR"];
        default = "INFO";
        description = "Log level for listener service";
      };
    };
  };

  config = mkMerge [
    # Audio service
    (mkIf cfg.audio.enable {
      systemd.user.services.ovos-audio = {
        Unit = {
          Description = "OpenVoiceOS Audio Service (TTS)";
          After = ["default.target"];
        };

        Service = {
          Type = "simple";
          ExecStart = "${cfg.audio.package}/bin/ovos-audio";
          Restart = "on-failure";
          RestartSec = "5s";

          Environment = [
            "OVOS_LOG_LEVEL=${cfg.audio.logLevel}"
            # User session naturally has access to XDG directories
            # and PulseAudio/PipeWire session
          ];
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };

      # Create minimal config pointing to messagebus
      # The system-wide config at /etc/mycroft/mycroft.conf will be used as base
      xdg.configFile."mycroft/mycroft.conf".text = builtins.toJSON {
        websocket = {
          host = cfg.messagebusHost;
          port = cfg.messagebusPort;
        };
      };
    })

    # Listener service (placeholder for future implementation)
    (mkIf cfg.listener.enable {
      systemd.user.services.ovos-listener = {
        Unit = {
          Description = "OpenVoiceOS Listener Service (STT)";
          After = ["default.target"];
        };

        Service = {
          Type = "simple";
          # ExecStart will be added when ovos-listener is packaged
          Restart = "on-failure";
          RestartSec = "5s";

          Environment = [
            "OVOS_LOG_LEVEL=${cfg.listener.logLevel}"
          ];
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
  ];
}
