{% from "icinga2/map.jinja" import icinga2 with context %}


{%- if grains['os'] == 'Debian' %}
# This repository also requires Debian Backports repository
icinga2_repo:
  pkgrepo.managed:
    - humanname: Official Icinga2 package repository
    - name: deb http://packages.icinga.org/debian icinga-{{ salt['grains.get']('oscodename') }} main
    - key_url: http://packages.icinga.com/icinga.key
{%- elif grains['os'] == 'Ubuntu' %}
icinga2_repo:
  pkgrepo.managed:
    - humanname: Official Icinga2 package repository
    - name: deb http://packages.icinga.com/ubuntu icinga-{{ salt['grains.get']('oscodename') }} main
    - key_url: http://packages.icinga.com/icinga.key
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
