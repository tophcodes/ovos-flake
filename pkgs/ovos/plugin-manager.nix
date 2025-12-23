{
  lib,
  buildPythonPackage,
  fetchPypi,
  ovos-config,
  ovos-utils,
  ovos-bus-client,
  langcodes,
  quebra-frases,
}:
buildPythonPackage rec {
  pname = "ovos-plugin-manager";
  version = "0.9.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Urpm80BSoXup48ElH7oLYRBFJ33sNQqoGhw9wGY8RKk=";
  };

  propagatedBuildInputs = [
    ovos-config
    ovos-utils
    ovos-bus-client
    langcodes
    quebra-frases
  ];

  # Create dummy requirements files
  postUnpack = ''
    mkdir -p $sourceRoot/requirements 2>/dev/null || true
    touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false; # Skip tests for now

  meta = with lib; {
    description = "OpenVoiceOS plugin manager for loading plugins";
    homepage = "https://github.com/OpenVoiceOS/ovos-plugin-manager";
    license = licenses.asl20;
    maintainers = [];
  };
}
