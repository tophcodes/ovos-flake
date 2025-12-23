{
  lib,
  buildPythonPackage,
  fetchPypi,
  quebra-frases,
  unicode-rbnf,
}:
buildPythonPackage rec {
  pname = "ovos-number-parser";
  version = "0.5.1";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Olx3GiW/gB/PNatpIxhd6PlvSzcQEE1lvitX8G3/5Dc=";
  };

  propagatedBuildInputs = [
    quebra-frases
    unicode-rbnf
  ];

  doCheck = false;

  pythonImportsCheck = ["ovos_number_parser"];

  meta = with lib; {
    description = "OVOS number parser - parse and pronounce numbers in multiple languages";
    homepage = "https://github.com/OpenVoiceOS/ovos-number-parser";
    license = licenses.asl20;
    maintainers = [];
  };
}
