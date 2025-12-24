{
  lib,
  buildPythonPackage,
  fetchPypi,
  ovos-plugin-manager,
  ovos-utils,
  pyaudio,
  pydub,
  setuptools,
}:
buildPythonPackage rec {
  pname = "ovos-audio-plugin-simple";
  version = "0.1.3";
  format = "setuptools";

  src = fetchPypi {
    pname = "ovos_audio_plugin_simple";
    inherit version;
    hash = "sha256-o/bvLt2E4x1TaMN4ysF8JY4wCLvrHUZQ++WXIycCWOk=";
  };

  propagatedBuildInputs = [
    ovos-plugin-manager
    ovos-utils
    pyaudio
    pydub
    setuptools  # Provides distutils compatibility for Python 3.13
  ];

  postUnpack = ''
    touch $sourceRoot/requirements.txt 2>/dev/null || true
  '';

  doCheck = false;

  # Disable import check - plugin imports distutils at runtime
  # which is provided by setuptools in propagatedBuildInputs
  pythonImportsCheck = [];

  meta = with lib; {
    description = "Simple audio playback plugin for OpenVoiceOS";
    homepage = "https://github.com/OpenVoiceOS/ovos-audio-plugin-simple";
    license = licenses.asl20;
    maintainers = [];
  };
}
