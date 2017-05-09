include:
  - icinga2.web

icingaweb2_director_pkgs:
  pkg.installed:
    - pkgs:
      - php5-curl
      - git

director-db-user:
  postgres_user.present:
    - name: {{ director_db_user }}
    - password: {{ director_db_password }}
    - require:
      - sls: icinga2.postgresql

director-db:
  postgres_database.present:
    - name: {{ director_db_name }}
    - owner: {{ director_db_user }}
    - owner_recurse: True
    - require:
      - postgres_user: director-db-user

director_dir:
  git.latest:
    - target: /usr/share/icingaweb2/modules/director
    - name: https://github.com/Icinga/icingaweb2-module-director.git
    - require:
      - pkg: icingaweb2_pkgs
    - force_fetch: True

migrate_director:
  cmd.run:
    - name: icingacli director migration run --verbose
    - onchanges:
      - git: director_dir
    - require:
      - cmd: enable_director_module
      - cmd: enable_api_feature

enable_director_module:
  cmd.run:
    - unless: icingacli module list | grep director | grep enabled
    - name: icingacli module enable director
    - require:
      - git: director_dir

enable_api_feature:
  cmd.run:
    - name: icinga2 feature enable api
    - watch_in:
      - service: icinga2
    - unless: icinga2 feature list | grep Enabled | grep api

configure_api:
  cmd.run:
    - name: icinga2 api setup
    - onchanges:
      - cmd: enable_api_feature
    - watch_in:
      - service: icinga2
