include:
  - icinga2

enable_command_feature:
  cmd.run:
    - name: icinga2 feature enable command
    - watch_in:
      - service: icinga2
    - unless: icinga2 feature list | grep Enabled | grep command
