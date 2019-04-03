{% from "icinga2/map.jinja" import icinga2 with context %}


{%- if grains['os'] in ['Debian', 'Ubuntu'] %}
# This repository also requires Debian Backports repository
icinga2_repo:
  pkgrepo.managed:
    - humanname: Official Icinga2 package repository
    - name: deb http://packages.icinga.org/{{ salt['grains.get']('os')|lower }} icinga-{{ salt['grains.get']('oscodename') }} main
    - key_url: http://packages.icinga.com/icinga.key
    - file: /etc/apt/sources.list.d/icinga.list
{%- elif grains['os'] == 'RedHat' %}
# TODO: RedHat repo info goes here
{%- endif %}


icinga2_pkg:
  pkg.installed:
    - name: {{ icinga2.package }}
    - require:
      - pkgrepo: icinga2_repo

icinga2_service:
  service.running:
    - name: {{ icinga2.service }}
    - enable: True
    - reload: True
    - require:
      - pkg: icinga2_pkg
