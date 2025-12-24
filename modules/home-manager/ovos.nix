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

  # Import OVOS packages directly so module doesn't depend on overlay
  ovosPackages = pkgs.callPackage ../../pkgs/ovos {};
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
        default = ovosPackages.ovos-audio;
        defaultText = literalExpression "ovosPackages.ovos-audio";
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
            # Add audio playback tools to PATH
            "PATH=${pkgs.lib.makeBinPath [ pkgs.pulseaudio pkgs.alsa-utils pkgs.ffmpeg-headless ]}:%h/.nix-profile/bin:/run/current-system/sw/bin"
          ];
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };

      # User config supplements system config at /etc/mycroft/mycroft.conf
      # OVOS merges both configs, user config takes precedence
      xdg.configFile."mycroft/mycroft.conf".text = builtins.toJSON {
        websocket = {
          host = cfg.messagebusHost;
          port = cfg.messagebusPort;
        };
        # Include TTS settings from system config
        # Note: In future, read these from config.services.ovos.speech.*
        tts = {
          module = "ovos-tts-plugin-piper";
          "ovos-tts-plugin-piper" = {
            voice = "en_US-lessac-medium";
          };
        };
        disable_ocp = true;
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
