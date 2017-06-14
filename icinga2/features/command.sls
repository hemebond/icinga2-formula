include:
  - icinga2

icinga2_command_enable:
  cmd.run:
    - name: icinga2 feature enable command
    - watch_in:
      - service: icinga2_service
    - unless: icinga2 feature list | grep Enabled | grep command
