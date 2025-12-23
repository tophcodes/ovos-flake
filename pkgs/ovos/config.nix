{
  lib,
  buildPythonPackage,
  fetchPypi,
  pyyaml,
  combo-lock,
  rich-click,
  ovos-utils,
}:
buildPythonPackage rec {
  pname = "ovos-config";
  version = "0.3.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-KqPH6WIZNvJ9ICZy+dikPp1kIr5S5F9SJPTdBlE4jIA=";
  };

  propagatedBuildInputs = [
    pyyaml
    combo-lock
    rich-click
    ovos-utils
  ];

  # Create dummy requirements files that setup.py expects
  postUnpack = ''
    # Create empty requirements files to satisfy setup.py
    mkdir -p $sourceRoot/requirements 2>/dev/null || true
    touch $sourceRoot/requirements/requirements.txt 2>/dev/null || true
    touch $sourceRoot/requirements/extras.txt 2>/dev/null || true
  '';

  doCheck = false; # Skip tests for now

  meta = with lib; {
    description = "OpenVoiceOS configuration manager";
    homepage = "https://github.com/OpenVoiceOS/ovos-config";
    license = licenses.asl20;
    maintainers = [];
  };
}
