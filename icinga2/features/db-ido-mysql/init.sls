{%- from "icinga2/map.jinja" import icinga2 with context %}

icinga2-ido-mysql:
  pkg.installed:
    - watch_in:
      - service: icinga2

enable_ido:
  cmd.run:
    - name: icinga2 feature enable ido-mysql
    - require:
      - pkg: icinga2-ido-mysql
    - watch_in:
      - service: icinga2
    - unless: icinga2 feature list | grep Enabled | grep ido-mysql

/etc/icinga2/features-available/ido-mysql.conf:
  file.managed:
    - source: salt://icinga2/features/db-ido-mysql/ido-mysql.conf.jinja
    - template: jinja
    - context:
        settings: {{ icinga2.features.get('ido_mysql') }}
