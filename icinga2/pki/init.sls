{% from 'icinga2/map.jinja' import icinga2 with context %}

# Install python-m2crypto dependency
{{icinga2.pki_pkg}}:
  pkg.installed:
    - reload_modules: True
    - require:
      - pkg: icinga2_pkg

icinga2_pki_dir:
  file.directory:
    - name: {{ icinga2.pki_dir }}
    - user: {{ icinga2.user }}
    - group: {{ icinga2.group }}
    - require:
      - pkg: {{icinga2.pki_pkg}}
