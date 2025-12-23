{
  lib,
  buildPythonPackage,
  fetchPypi,
}:
buildPythonPackage rec {
  pname = "kthread";
  version = "0.2.3";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-kOGU5qf/kDBAxBM9PqkDfJCMQpa/X1gsf9z2MloE+bQ=";
  };

  # No dependencies
  propagatedBuildInputs = [];

  doCheck = false; # No tests in package

  meta = with lib; {
    description = "Killable threads in Python";
    homepage = "https://github.com/munshigroup/kthread";
    license = licenses.mit;
    maintainers = [];
  };
}
