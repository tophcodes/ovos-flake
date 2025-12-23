{
  lib,
  buildPythonApplication,
  fetchPypi,
  ovos-utils,
  ovos-bus-client,
  ovos-config,
  ovos-plugin-manager,
  ovos-tts-plugin-piper,
}:
buildPythonApplication rec {
  pname = "ovos-audio";
  version = "1.0.1";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-ZCiqce1thY9eMzGcb1hYFy7YwcLJKITJgkjZYg0hPz0=";
  };

  propagatedBuildInputs = [
    ovos-utils
    ovos-bus-client
    ovos-config
    ovos-plugin-manager
    ovos-tts-plugin-piper  # Include piper TTS plugin
  ];

  # Create dummy requirements files
  postUnpack = ''
    mkdir -p $sourceRoot/requirements 2>/dev/null || true
    touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
    touch $sourceRoot/requirements/extras.txt 2>/dev/null || true
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false; # Skip tests for now

  meta = with lib; {
    description = "OpenVoiceOS audio service - The 'mouth' of the assistant";
    homepage = "https://github.com/OpenVoiceOS/ovos-audio";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "ovos-audio";
  };
}
