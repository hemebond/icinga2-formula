#!py

import re
import yaml
import imp
from jinja2 import Environment, Template

icinga2_globals = [
	'Acknowledgement',
	'ApplicationType',
	'AttachDebugger',
	'BuildCompilerName',
	'BuildCompilerVersion',
	'BuildHostName',
	'Concurrency',
	'Critical',
	'Custom',
	'Deprecated',
	'Down',
	'DowntimeEnd',
	'DowntimeRemoved',
	'DowntimeStart',
	'FlappingEnd',
	'FlappingStart',
	'HostDown',
	'HostUp',
	'IncludeConfDir',
	'Internal',
	'Json',
	'LocalStateDir',
	'LogCritical',
	'LogDebug',
	'LogInformation',
	'LogNotice',
	'LogWarning',
	'Math',
	'ModAttrPath',
	'NodeName',
	'ObjectsPath',
	'OK',
	'PidPath',
	'PkgDataDir',
	'PlatformArchitecture',
	'PlatformKernel',
	'PlatformKernelVersion',
	'PlatformName',
	'PlatformVersion',
	'PrefixDir',
	'Problem',
	'Recovery',
	'RunAsGroup',
	'RunAsUser',
	'RunDir',
	'ServiceCritical',
	'ServiceOK',
	'ServiceUnknown',
	'ServiceWarning',
	'StatePath',
	'SysconfDir',
	'System',
	'Types',
	'Unknown',
	'Up',
	'UseVfork',
	'VarsPath',
	'Warning',
	'ZonesDir',
]


def run():
	config = {}

	pth = __salt__.cp.cache_file("salt://icinga2/utils.py")
	m = imp.load_source('icinga2salt', pth)

	# Add support for the `do` jinja tag
	jinja_env = Environment(extensions=['jinja2.ext.do'])

	# Fetch and render the map file for OS settings
	osmap_file = __salt__.cp.cache_file("salt://icinga2/map.jinja")
	osmap_tpl = jinja_env.from_string(open(osmap_file, 'r').read())
	osmap_mod = osmap_tpl.make_module(vars={'salt': __salt__})
	osmap = osmap_mod.icinga2

	# Render the defaults.jinja file to get default configuration items
	defaults_file = __salt__.cp.cache_file("salt://icinga2/defaults.yaml")
	with open(defaults_file, 'r') as stream:
		defaults = yaml.load(stream)

	icinga2_constants = osmap['constants'].copy()

	# print(defaults)

	templates = ""
	result = ""

	# This defines in which file we want to store each object type
	configuration_file_map = {
		'apiuser': '/conf.d/api-users.conf',
		'checkcommand': '/conf.d/commands.conf',
		'dependency': '/conf.d/dependencies.conf',
		'endpoint': '/zones.conf',
		'eventcommand': '/conf.d/commands.conf',
		'host': '/conf.d/hosts.conf',
		'hostgroup': '/conf.d/groups.conf',
		'notification': '/conf.d/notifications.conf',
		'notificationcommand': '/conf.d/commands.conf',
		'scheduleddowntime': '/conf.d/downtimes.conf',
		'service': '/conf.d/services.conf',
		'servicegroup': '/conf.d/groups.conf',
		'template': '/conf.d/templates.conf',
		'timeperiod': '/conf.d/timeperiods.conf',
		'user': '/conf.d/users.conf',
		'usergroup': '/conf.d/users.conf',
		'zone': '/zones.conf',
	}

	# Hold the object definitions for a particular config file
	definition_store = {
		'/conf.d/templates.conf': ''
	}

	for obj_type, obj_definitions in defaults.get('conf', {}).iteritems():
		for obj_name, obj_info in obj_definitions.iteritems():
			cfg_file = configuration_file_map[obj_type]

			# Initialise the definition store for this object type
			if cfg_file not in definition_store:
				definition_store[cfg_file] = ''

			try:
				obj_function_name = 'icinga2_object_%s' % obj_type
				obj_function = getattr(m, obj_function_name)
				definition = obj_function(obj_name, obj_info, icinga2_globals, icinga2_constants) + "\n\n"

				if obj_info.get('template', False):
					definition_store['/conf.d/templates.conf'] += definition
				else:
					definition_store[cfg_file] += definition
			except KeyError as e:
				print('No function found for %s' % obj_type)
				print(e)

	# Create the states for each file
	for filename, contents in definition_store.iteritems():
		config[osmap['conf_dir'] + filename] = {
			'file.managed': [
				{'user': osmap['user']},
				{'group': osmap['group']},
				{'mode': 600},
				{'contents': contents},
				{'watch_in': {
					'service': 'icinga2-reload'
				}}
			]
		}

	# print(result)
	# print(templates)
	# print(config)

	return config