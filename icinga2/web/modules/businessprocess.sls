include:
  - icinga2.web

icingaweb2_businessprocess_module_dir:
  git.latest:
    - target: /usr/share/icingaweb2/modules/businessprocess
    - name: https://github.com/Icinga/icingaweb2-module-businessprocess
    - require:
      - pkg: icingaweb2_pkgs
    - force_fetch: True

icingaweb2_enable_businessprocess_module:
  cmd.run:
    - unless: icingacli module list | grep businessprocess | grep enabled
    - name: icingacli module enable businessprocess
    - require:
      - pkg: icingaweb2_pkgs
