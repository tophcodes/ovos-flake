{
  lib,
  buildPythonPackage,
  fetchPypi,
  ovos-plugin-manager,
  ovos-utils,
  langcodes,
  onnxruntime,
  numpy,
  quebra-frases,
}:
buildPythonPackage rec {
  pname = "ovos-tts-plugin-piper";
  version = "0.2.5";
  format = "setuptools";

  src = fetchPypi {
    pname = "ovos_tts_plugin_piper";
    inherit version;
    hash = "sha256-Rt9ef0hnVhUBdibLBRTqtt/Pdc1woiytr803Mrb4PW8=";
  };

  propagatedBuildInputs = [
    ovos-plugin-manager
    ovos-utils
    langcodes
    onnxruntime
    numpy
    quebra-frases
  ];

  # Create dummy requirements files
  postUnpack = ''
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false;

  pythonImportsCheck = ["ovos_tts_plugin_piper"];

  meta = with lib; {
    description = "Piper TTS plugin for OpenVoiceOS";
    homepage = "https://github.com/OpenVoiceOS/ovos-tts-plugin-piper";
    license = licenses.asl20;
    maintainers = [];
  };
}
