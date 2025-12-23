{
  lib,
  buildPythonPackage,
  fetchPypi,
  requests,
  python-dateutil,
  kthread,
}:
buildPythonPackage rec {
  pname = "ovos-utils";
  version = "0.2.1";
  format = "setuptools";

  src = fetchPypi {
    pname = "ovos_utils"; # PyPI uses underscore
    inherit version;
    hash = "sha256-qojQqM/WqNZMpWi3K0lj+lxoZmHIS1WrhyEx1NyZQLM=";
  };

  propagatedBuildInputs = [
    requests
    python-dateutil
    kthread
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
    description = "OpenVoiceOS utility library";
    homepage = "https://github.com/OpenVoiceOS/ovos-utils";
    license = licenses.asl20;
    maintainers = [];
  };
}
