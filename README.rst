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
* Run Icinga2 service

``icinga.web``
--------------

* Install and configures IcingaWeb2
* Import database schema
* Enables Icinga2 features required

``icinga2.node``
----------------

* Run pki node
* Run config
* Run features

``icinga2.master``
------------------

* Run pki master
* Run config
* Run features
