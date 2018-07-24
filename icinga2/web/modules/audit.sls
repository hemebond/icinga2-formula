include:
  - icinga2.web

icingaweb2_audit_dir:
  git.latest:
    - target: /usr/share/icingaweb2/modules/audit
    - name: https://github.com/Icinga/icingaweb2-module-audit.git
    - require:
      - pkg: icingaweb2_pkgs
    - force_fetch: True

icingaweb2_enable_audit_module:
  cmd.run:
    - unless: icingacli module list | grep audit | grep enabled
    - name: icingacli module enable audit
    - require:
      - pkg: icingaweb2_pkgs
