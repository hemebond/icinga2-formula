icinga2_api_disable:
  cmd.run:
    - name: icinga2 feature disable api
    - watch_in:
      - service: icinga2_service
    - onlyif: icinga2 feature list | grep Enabled | grep -w api
