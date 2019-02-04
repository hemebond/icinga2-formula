icinga2_syslog_enable:
  cmd.run:
    - name: icinga2 feature enable syslog
    - watch_in:
      - service: icinga2_service
    - unless: icinga2 feature list | grep Enabled | grep -w syslog
