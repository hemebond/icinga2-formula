{% from 'icinga2/map.jinja' import icinga2 with context %}

include:
  - icinga2

icinga2_api_conf:
  file.managed:
    - name: {{ conf_dir }}/features-available/api.conf
    - source: salt://icinga2/features/api/api.conf.jinja
    - template: jinja
    - user: {{icinga2.user}}
    - group: {{icinga2.group}}
    - require:
      - pkg: icinga2_pkg


icinga2_api_enable:
  cmd.run:
    - name: icinga2 feature enable api
    - watch_in:
      - service: icinga2
    - unless: icinga2 feature list | grep Enabled | grep -w api
