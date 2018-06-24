include:
  - icinga2.web

icingaweb2_graphite_dir:
  git.latest:
    - target: /usr/share/icingaweb2/modules/graphite
    - name: https://github.com/Icinga/icingaweb2-module-graphite.git
    - require:
      - pkg: icingaweb2_pkgs
    - force_fetch: True

icingaweb2_enable_graphite_module:
  cmd.run:
    - unless: icingacli module list | grep graphite | grep enabled
    - name: icingacli module enable graphite
    - require:
      - pkg: icingaweb2_pkgs
