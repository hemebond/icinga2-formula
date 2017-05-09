{%- if grains['os'] == 'Debian' %}

# This repository also requires Debian Backports repository
icinga2_package_repository:
  pkgrepo.managed:
    - humanname: Official Icinga2 package repository
    - name: deb http://packages.icinga.org/debian/ icinga-{{ salt['grains.get']('oscodename') }} main
    - key_url: http://packages.icinga.com/icinga.key

# icinga_repo:
#   pkgrepo.managed:
#     - humanname: debmon
#     - name: deb http://debmon.org/debmon debmon-{{ grains['oscodename'] }} main
#     - file: /etc/apt/sources.list.d/debmon.list
#     - key_url: http://debmon.org/debmon/repo.key
#     - require:
#       - pkg: debmon_repo_required_packages


{%- elif grains['os'] == 'Ubuntu' %}

icinga2_package_repository:
  pkgrepo.managed:
    - humanname: Official Icinga2 package repository
    - name: deb http://packages.icinga.com/ubuntu icinga-{{ salt['grains.get']('oscodename') }} main
    - key_url: http://packages.icinga.com/icinga.key

# icinga_repo:
#   pkgrepo.managed:
#     - ppa: formorer/icinga

{%- elif grains['os'] == 'RedHat' %}

# TODO: RedHat repo info goes here

{%- endif %}
