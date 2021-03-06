{%- from "icinga2/map.jinja" import icinga2 with context %}

icinga2-ido-mysql:
  pkg.installed:
    - watch_in:
      - service: icinga2

icinga2_ido_enable:
  cmd.run:
    - name: icinga2 feature enable ido-mysql
    - require:
      - pkg: icinga2-ido-mysql
    - watch_in:
      - service: icinga2_service
    - unless: icinga2 feature list | grep Enabled | grep -w ido-mysql

/etc/icinga2/features-available/ido-mysql.conf:
  file.managed:
    - source: salt://icinga2/features/ido-mysql/ido-mysql.conf.jinja
    - template: jinja
    - context:
        db: {{ icinga2.features.get('ido_mysql') }}
