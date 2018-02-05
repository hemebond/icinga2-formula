include:
  - icinga2.web

icingaweb2_grafana_pkgs:
  pkg.installed:
    - pkgs:
      - php5-curl
      - git

icingaweb2_grafana_dir:
  git.latest:
    - target: /usr/share/icingaweb2/modules/grafana
    - name: https://github.com/Mikesch-mp/icingaweb2-module-grafana.git
    - require:
      - pkg: icingaweb2_pkgs
    - force_fetch: True

icingaweb2_enable_grafana_module:
  cmd.run:
    - unless: icingacli module list | grep grafana | grep enabled
    - name: icingacli module enable grafana
    - require:
      - pkg: icingaweb2_pkgs
