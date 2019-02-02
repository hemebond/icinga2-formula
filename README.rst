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

``icinga2.client``
------------------

Installs Icinga2 as a client agent, creating client certificates against an Icinga2 master. Requires `permissions for remote signing <https://docs.saltstack.com/en/latest/ref/states/all/salt.states.x509.html>`_.

.. code-block:: yaml

    # Example client/agent configuration
    icinga2:
      lookup:
        master_fqdn: icinga.example.com
        master_minion_id: icinga
        constants:
          PluginContribDir: /usr/local/lib/monitoring-plugins
        features:
          # Make sure the API on clients/agents
          # is only accessible to localhost
          api:
            accept_config: true
            accept_commands: true
            bind_host: '127.0.0.1'
          # Reduce the logging level from
          # information to warning
          mainlog:
            severity: warning
        conf:
          zone:
            master:
              endpoints:
                - icinga.example.com
            ZoneName:
              endpoints:
                - NodeName
              parent: master
            # Enable the global-templates zone so that
            # commands are automatically synced
            global-templates:
              global: True
          endpoint:
            NodeName: {}
            icinga.example.com:
              host: icinga.example.com
    

``icinga2.features.api``
------------------------

Enable and configure the ``api`` feature.

.. code-block:: yaml

    # Example ApiListener configuration.
    icinga2:
      lookup:
        features:
          api:
            ca_path: /var/lib/icinga2/ca/ca.crt

``icinga2.features.db-ido-pgsql``
---------------------------------

Enables and configures the ``ido-pgsql`` feature.

.. code-block:: yaml

    # Example IdoPgsqlConnection configuration
    icinga2:
      lookup:
        features:
          ido-pgsql:
            host: localhost
            port: 5432
            name: icinga
            user: root
            password: password
    
``icinga2.features.debuglog``
-----------------------------

Enable and configure the `debuglog` feature. Use the ``icinga2.features.debuglog.disabled`` state to disable the feature.

.. code-block:: yaml

    # Example FileLogger configuration
    icinga2:
      lookup:
        features:
          debuglog:
            path: LogDir + "/debug.log"

``icinga2.features.graphite``
-----------------------------

Enable and configure the ``graphite`` feature.

.. code-block:: yaml

    # Example GraphiteWriter configuration
    icinga2:
      lookup:
        features:
          graphite:
            enable_send_thresholds: True
            enable_send_metadata: True
    
``icinga2.features.mainlog``
----------------------------

Enable and configure the ``mainlog`` feature.

.. code-block:: yaml

    # Example FileLogger configuration
    icinga2:
      lookup:
        features:
          mainlog:
            severity: critical

``icinga2.master``
------------------

Installs and configures an Icinga2 master with a CA for generating client certs for Icinga2 agents. Requires `permissions for remote signing <https://docs.saltstack.com/en/latest/ref/states/all/salt.states.x509.html>`_.

.. code-block:: yaml

    # Example Icinga2 master configuration
    icinga2:
      lookup:
        master_fqdn: icinga.example.com
        master_minion_id: icinga
        constants:
          TicketSalt: iamarandomstring
          PluginContribDir: /usr/local/lib/monitoring-plugins
        plugins:
          - itl
          - plugins
          - plugins-contrib

``icinga2.web``
---------------

Installs and configures Icingaweb2.

.. code-block:: yaml

    icinga2:
      lookup:
        web:
          user: www-data
          group: icingaweb2
    
          global:
            show_stacktraces: 1
    
          logging:
            log: syslog
            level: ERROR
    
          db:
            host: localhost
            port: 5432
            name: icingaweb2
            user: root
            password: password
            type: pgsql

``icinga2.web.modules.audit``
-----------------------------

Changes
=======

2018-06-21
----------

Pillar key for IDO features have changed to match the feature name:

* ido_pgsql > ido-pgsql
* ido_mysql > ido-mysql
