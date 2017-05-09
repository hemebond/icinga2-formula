{%- from "icinga2/map.jinja" import icinga2 with context %}

include:
  - icinga2.features.command
  - icinga2.features.syslog

{%- set config = icinga2.get('web', {}) %}

icingaweb2_pkgs:
  pkg.installed:
    - pkgs:
      - icingaweb2
      - icingaweb2-module-monitoring
      - icingacli


# TODO: Make schema path a variable
{%- if icinga2.web.db.type == 'pgsql' %}
icingaweb2-database-schemas:
  cmd.run:
    - name: psql -v ON_ERROR_STOP=1 --host={{ icinga2.web.db.host }} --dbname={{ icinga2.web.db.name }} --username={{ icinga2.web.db.user }} < /usr/share/icingaweb2/etc/schema/pgsql.schema.sql
    - env:
      - PGPASSWORD: {{ icinga2.web.db.password }}
    - unless: PGPASSWORD={{ icinga2.web.db.password }} psql -v ON_ERROR_STOP=1 --host={{ icinga2.web.db.host }} --dbname={{ icinga2.web.db.name }} --username={{ icinga2.web.db.user }} -c "SELECT * FROM icingaweb_user;"
    - require:
      - pkg: icingaweb2_pkgs
{%- endif %}


{%- for username, password_hash in icinga2.web.get('users', {}).iteritems() %}
# TODO: handling for password change via pillar atm
{%-   if icinga2.web.db.type == 'pgsql' %}
icingaweb2-user-{{ username }}:
  cmd.run:
    - name: echo "INSERT INTO icingaweb_user (name, active, password_hash) VALUES ('{{ username }}', 1, '{{ password_hash|replace('$', '\$') }}');" | psql -v ON_ERROR_STOP=1 --host={{ icinga2.web.db.host }} --dbname={{ icinga2.web.db.name }} --username={{ icinga2.web.db.user }}
    - env:
      - PGPASSWORD: {{ icinga2.web.db.password }}
    - unless: echo "SELECT * FROM icingaweb_user where name='{{ username }}';" | psql -v ON_ERROR_STOP=1 --host={{ icinga2.web.db.host }} --dbname={{ icinga2.web.db.name }} --username={{ icinga2.web.db.user }} | grep {{ username }}
{%-   endif %}
{%- endfor %}


/etc/icingaweb2:
  file.recurse:
    - source: salt://icinga2/files/web
    - template: jinja
    - user: {{ icinga2.web.user }}
    - group: {{ icinga2.web.group }}
    # - dir_mode: 2775
    - dir_mode:
    - file_mode: 644
    - require:
      - pkg: icingaweb2_pkgs
    - context:
        icinga2: {{ icinga2 }}
        icingaweb_db: {{ icinga2.web.db | default({}) }}
        director_db: {{ icinga2.web.modules.director.db | default({}) }}

enable_monitoring_module:
  cmd.run:
    - unless: icingacli module list | grep monitoring | grep enabled
    - name: icingacli module enable monitoring
    - require:
      - pkg: icingaweb2_pkgs
