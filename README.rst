===============
icinga2-formula
===============

A salt formula that installs and configures Icinga2. Based on the `Icinga2 Puppet module <https://github.com/Icinga/puppet-icinga2>`_ by the Icinga2 team.

Available states
================

.. contents::
    :local:

``icinga2``
-----------

* Configure Icinga2 repository
* Install Icinga2
* Configure Icinga2 with a set of defaults
* Manage Icinga2 service

``icinga2.web``
---------------

Installs and configures Icingaweb2.

``icinga2.client``
------------------

Installs Icinga2 as a client agent, creating client certificates against an Icinga2 master. Requires `permissions for remote signing <https://docs.saltstack.com/en/latest/ref/states/all/salt.states.x509.html>`_.

``icinga2.master``
------------------

Installs and configures an Icinga2 master with a CA for generating client certs for Icinga2 agents. Requires `permissions for remote signing <https://docs.saltstack.com/en/latest/ref/states/all/salt.states.x509.html>`_.

Changes
=======

2018-06-21
----------
Pillar key for IDO features have changed to match the feature name:

* ido_pgsql > ido-pgsql
* ido_mysql > ido-mysql
