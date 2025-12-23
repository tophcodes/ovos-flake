{
  lib,
  buildPythonPackage,
  fetchPypi,
  websocket-client,
  pyee,
  orjson,
  ovos-config,
  ovos-utils,
}:
buildPythonPackage rec {
  pname = "ovos-bus-client";
  version = "0.1.3";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Q/40rqCvwHuaZvSdke+aRGZxMf52FwmxqeDv+D2de6A=";
  };

  propagatedBuildInputs = [
    websocket-client
    pyee
    orjson
    ovos-config
    ovos-utils
  ];

  # Create dummy requirements files that setup.py expects
  postUnpack = ''
    # Create empty requirements files to satisfy setup.py
    mkdir -p $sourceRoot/requirements 2>/dev/null || true
    touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false; # Skip tests for now

  meta = with lib; {
    description = "OpenVoiceOS bus client for messagebus communication";
    homepage = "https://github.com/OpenVoiceOS/ovos-bus-client";
    license = licenses.asl20;
    maintainers = [];
  };
}
