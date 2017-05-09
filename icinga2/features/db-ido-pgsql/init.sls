{%- from "icinga2/map.jinja" import icinga2 with context %}

{%- set db = icinga2.features.get('ido_pgsql') %}

icinga2-ido-pgsql:
  pkg.installed:
    - watch_in:
      - service: icinga2

enable_ido:
  cmd.run:
    - name: icinga2 feature enable ido-pgsql
    - require:
      - pkg: icinga2-ido-pgsql
    - watch_in:
      - service: icinga2
    - unless: icinga2 feature list | grep Enabled | grep ido-pgsql

/etc/icinga2/features-available/ido-pgsql.conf:
  file.managed:
    - source: salt://icinga2/features/db-ido-pgsql/ido-pgsql.conf.jinja
    - template: jinja
    - context:
        db: {{ db }}

# TODO: Make schema path a variable
icinga2-ido-database-schema:
  cmd.run:
    - name: psql -v ON_ERROR_STOP=1 --host={{ db.host }} --dbname={{ db.name }} --username={{ db.user }} < /usr/share/icinga2-ido-pgsql/schema/pgsql.sql
    - env:
      - PGPASSWORD: {{ db.password }}
    - unless: PGPASSWORD={{ db.password }} psql --host={{ db.host }} --dbname={{ db.name }} --username={{ db.user }} -c "SELECT * FROM icinga_dbversion;"
    - require:
      - pkg: icinga2-ido-pgsql
