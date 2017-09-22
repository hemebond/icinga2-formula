{% from 'icinga2/map.jinja' import icinga2 with context %}

include:
  - icinga2.pki.client
  - icinga2.config
  - icinga2.features.api



extend:
  icinga2_api_enable:
    cmd:
      - require:
        - file: icinga2_client_master_cert_perms
        - file: icinga2_client_cert_perms
        - file: icinga2_client_key_perms
