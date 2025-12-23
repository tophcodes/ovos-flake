{
  lib,
  buildPythonPackage,
  fetchPypi,
  ovos-bus-client,
  ovos-config,
  ovos-utils,
  ovos-plugin-manager,
  ovos-number-parser,
  requests,
}:
buildPythonPackage rec {
  pname = "ovos-workshop";
  version = "3.1.2";
  format = "setuptools";

  src = fetchPypi {
    pname = "ovos_workshop";
    inherit version;
    hash = "sha256-tF3Y52JbpOrZXiEDbkUyMzuaD0amYbwa9Oodt9ud9Y0=";
  };

  propagatedBuildInputs = [
    ovos-bus-client
    ovos-config
    ovos-utils
    ovos-plugin-manager
    ovos-number-parser
    requests
  ];

  # Create dummy requirements files
  postUnpack = ''
    mkdir -p $sourceRoot/requirements 2>/dev/null || true
    touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false; # Skip tests for now

  meta = with lib; {
    description = "OpenVoiceOS skill framework and base classes";
    homepage = "https://github.com/OpenVoiceOS/ovos-workshop";
    license = licenses.asl20;
    maintainers = [];
  };
}
