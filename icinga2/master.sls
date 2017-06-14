include:
  - icinga2.pki.master
  - icinga2.config
  - icinga2.features

extend:
  icinga2_api_enable:
    cmd:
      - require:
        - x509: icinga2_node_ca_cert
        - x509: icinga2_node_cert
