{
  lib,
  buildPythonPackage,
  fetchPypi,
}:
buildPythonPackage rec {
  pname = "quebra-frases";
  version = "0.3.7";
  format = "setuptools";

  src = fetchPypi {
    pname = "quebra_frases";
    inherit version;
    hash = "sha256-7IOc6IJaUKxnHS3/CfGoVj0WhvSVSSStDG483o4nftA=";
  };

  propagatedBuildInputs = [];

  doCheck = false;

  pythonImportsCheck = ["quebra_frases"];

  meta = with lib; {
    description = "Portuguese sentence tokenizer";
    homepage = "https://github.com/OpenVoiceOS/quebra_frases";
    license = licenses.asl20;
    maintainers = [];
  };
}
