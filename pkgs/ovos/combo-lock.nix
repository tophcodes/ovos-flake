{
  lib,
  buildPythonPackage,
  fetchPypi,
  filelock,
  memory-tempfile,
}:
buildPythonPackage rec {
  pname = "combo-lock";
  version = "0.2.5";
  format = "setuptools";

  src = fetchPypi {
    pname = "combo_lock"; # PyPI uses underscore
    inherit version;
    hash = "sha256-/XLUkUYoCrYSZ5pZszO2jAsBAlPiv4/bq9qct5DWDsg=";
  };

  propagatedBuildInputs = [
    filelock
    memory-tempfile
  ];

  doCheck = false; # No tests

  pythonImportsCheck = ["combo_lock"];

  meta = with lib; {
    description = "Named lock using platformdirs and filelock";
    homepage = "https://github.com/OpenVoiceOS/combo-lock";
    license = licenses.asl20;
    maintainers = [];
  };
}
