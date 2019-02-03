include:
  - icinga2
  - icinga2.pki.ca
  - icinga2.pki.cert
  - icinga2.config
  - icinga2.objects
  - icinga2.features.api

extend:
  icinga2_api_enable:
    cmd:
      - require:
        - file: icinga2_ca_cert_perms
        - file: icinga2_client_cert_perms
