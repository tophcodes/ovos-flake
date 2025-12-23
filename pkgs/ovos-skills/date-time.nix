{
  fetchPypi,
  buildOvosSkill,
}:
buildOvosSkill rec {
  pname = "ovos-skill-date-time";
  version = "1.1.5";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-MLqsQLl9vfGpcVQszimEfidPklJMUQV5n2/WPu3ilmY=";
  };

  skillId = "skill-ovos-date-time.openvoiceos";

  meta = {
    description = "OpenVoiceOS skill providing current time, date and day of week";
    homepage = "https://github.com/OpenVoiceOS/ovos-skill-date-time";
  };
}
