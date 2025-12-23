{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  fetchPypi,
  tornado,
  ovos-bus-client,
  ovos-utils,
  ovos-config,
}:
buildPythonApplication rec {
  pname = "ovos-messagebus";
  version = "0.0.10";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "OpenVoiceOS";
    repo = "ovos-messagebus";
    rev = version;
    hash = "sha256-g0tEc5xdkKKIkIi0ryWlnA/ZZk18MgpK//DwhS21aJQ=";
  };

  propagatedBuildInputs = [
    tornado
    ovos-bus-client
    ovos-utils
    ovos-config
  ];

  # Create dummy requirements files and patch paths
  postUnpack = ''
    # Create empty requirements files to satisfy setup.py
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  postPatch = ''
    # OVOS typically uses ~/.config/mycroft or /opt/mycroft
    # We'll patch this to use /etc/ovos and /var/lib/ovos (if files exist)
    if [ -d ovos_messagebus ]; then
      find ovos_messagebus -name "*.py" -exec sed -i \
        -e "s|~/.config/mycroft|/etc/ovos|g" \
        -e "s|/opt/mycroft|/var/lib/ovos|g" {} + || true
    fi
  '';

  # Skip tests for now - will enable once dependencies are available
  doCheck = false;

  meta = with lib; {
    description = "OpenVoiceOS messagebus service - WebSocket message broker";
    homepage = "https://github.com/OpenVoiceOS/ovos-messagebus";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "ovos-messagebus";
  };
}
