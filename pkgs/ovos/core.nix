{
  lib,
  buildPythonApplication,
  fetchPypi,
  requests,
  python-dateutil,
  watchdog,
  rapidfuzz,
  langcodes,
  ovos-utils,
  ovos-bus-client,
  ovos-plugin-manager,
  ovos-config,
  ovos-workshop,
}:
buildPythonApplication rec {
  pname = "ovos-core";
  version = "2.1.1";
  format = "setuptools";

  src = fetchPypi {
    pname = "ovos_core";
    inherit version;
    hash = "sha256-TH/hgsXhnsj2VRv8T00UjDRLydnkB+3CWGp7IMwOKpM=";
  };

  propagatedBuildInputs = [
    requests
    python-dateutil
    watchdog
    rapidfuzz
    langcodes
    ovos-utils
    ovos-bus-client
    ovos-plugin-manager
    ovos-config
    ovos-workshop
  ];

  # Create dummy requirements files
  postUnpack = ''
    mkdir -p $sourceRoot/requirements 2>/dev/null || true
    touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false; # Skip tests for now

  meta = with lib; {
    description = "OpenVoiceOS Core - Skills engine and intent service";
    homepage = "https://github.com/OpenVoiceOS/ovos-core";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "ovos-core";
  };
}
