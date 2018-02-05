icinga2_debuglog_disable:
  cmd.run:
    - name: icinga2 feature disable debuglog
    - watch_in:
      - service: icinga2_service
    - onlyif: icinga2 feature list | grep Enabled | grep -w debuglog
