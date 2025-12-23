{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.elements.ovos;
in {
  options.services.elements.ovos = {
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
      default = pkgs.ovosPackages.ovos-messagebus;
      defaultText = literalExpression "pkgs.ovosPackages.ovos-messagebus";
      description = "The ovos-messagebus package to use";
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
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = ["/var/lib/ovos"];
      };

      environment = {
        OVOS_CONFIG_PATH = "/etc/ovos";
        OVOS_LOG_LEVEL = cfg.logLevel;
      };

      preStart = ''
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
          "log_level": "${cfg.logLevel}"
        }
        EOF
                  chown ovos:ovos /etc/ovos/mycroft.conf
                fi
      '';
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
