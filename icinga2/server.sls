{% from "icinga2/map.jinja" import icinga2 with context %}


include:
  - .repository
  - .config
  - .objects
{%- if 'ido_pgsql' in icinga2.features %}
  - .features.db-ido-pgsql
{%- elif 'ido_mysql' in icinga2.features %}
  - .features.db-ido-mysql
{%- endif %}

icinga2:
  pkg.installed:
    - require:
      - pkgrepo: icinga2_package_repository
  service.running:
    - enable: True

# A service state to just reload, not restart,
# the service when an object definition file changes
icinga2-reload:
  service.running:
    - name: icinga2
    - reload: True
