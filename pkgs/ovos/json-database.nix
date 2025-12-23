{
  lib,
  buildPythonPackage,
  fetchPypi,
  combo-lock,
}:
buildPythonPackage rec {
  pname = "json-database";
  version = "0.10.0";
  format = "setuptools";

  src = fetchPypi {
    pname = "json_database";
    inherit version;
    hash = "sha256-Tbe8XZ8vw3gFVPkgWAtpfJ4VYGhU76vhBYoUV9K2zIk=";
  };

  propagatedBuildInputs = [
    combo-lock
  ];

  # Create dummy requirements files that setup.py expects
  postUnpack = ''
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false; # No tests

  pythonImportsCheck = ["json_database"];

  meta = with lib; {
    description = "JSON-based database with search and storage capabilities";
    homepage = "https://github.com/OpenJarbas/json_database";
    license = licenses.asl20;
    maintainers = [];
  };
}
