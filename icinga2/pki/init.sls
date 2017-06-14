{% from 'icinga2/map.jinja' import icinga2 with context %}

include:
  - icinga2

icinga2_pki_dir:
  file.directory:
    - name: {{ icinga2.pki_dir }}
    - user: {{ icinga2.user }}
    - group: {{ icinga2.group }}
    - require:
      - pkg: icinga2_pkg
