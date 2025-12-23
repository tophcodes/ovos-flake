{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
}:
buildPythonPackage rec {
  pname = "pyee";
  version = "11.1.1";
  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-guHrGFP4SXxP8aDH+ia5zS8SU+K2/7k7RwD9qQcBcwI=";
  };

  # No runtime dependencies
  propagatedBuildInputs = [];

  doCheck = false; # Skip tests

  pythonImportsCheck = ["pyee"];

  meta = with lib; {
    description = "A port of Node.js's EventEmitter to Python";
    homepage = "https://github.com/jfhbrook/pyee";
    license = licenses.mit;
    maintainers = [];
  };
}
