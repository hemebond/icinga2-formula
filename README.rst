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

Installs Icinga2 as a client agent, creating client certificates against an Icinga2 master.

``icinga2.master``
------------------

Installs and configures an Icinga2 master with a CA for generating client certs for Icinga2 agents.
