{% from 'icinga2/map.jinja' import icinga2 with context %}
{% set id   = salt.grains.get('id') %}
{% set fqdn = salt.grains.get('fqdn') %}



include:
  - icinga2.pki



# Create the key
icinga2_client_key:
  x509.private_key_managed:
    - name: {{ icinga2.pki_dir }}/{{ fqdn }}.key
    - bits: 4096
    - backup: True
    - require:
      - file: icinga2_pki_dir
icinga2_client_key_perms:
  file.managed:
    - name: {{ icinga2.pki_dir }}/{{ fqdn }}.key
    - user: {{ icinga2.user }}
    - group: {{ icinga2.group }}
    - mode: 600
    - replace: False
    - watch:
      - x509: icinga2_client_key



# Create the certificate, send it to ca_server to be signed and store it as crt
icinga2_client_cert:
  x509.certificate_managed:
    - name: {{ icinga2.pki_dir }}/{{ fqdn }}.crt
    - ca_server: {{ icinga2.master_minion_id }}
    - signing_policy: icinga2
    - public_key: {{ icinga2.pki_dir }}/{{ fqdn }}.key
    - CN: {{ fqdn }}
    - backup: True
    - require:
      - x509: icinga2_client_key
    - unless:
      - ls {{ icinga2.pki_dir }}/{{ fqdn }}.crt
icinga2_client_cert_perms:
  file.managed:
    - name: {{ icinga2.pki_dir }}/{{ fqdn }}.crt
    - user: {{ icinga2.user }}
    - group: {{ icinga2.group }}
    - mode: 600
    - replace: False
    - onchanges:
      - x509: icinga2_client_cert
