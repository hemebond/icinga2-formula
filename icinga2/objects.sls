#!py

import re
import yaml
import imp
from jinja2 import Environment, Template


def run():
	config = {}

	utils_module_path = __salt__.cp.cache_file("salt://icinga2/utils.py")
	utils = imp.load_source('icinga2_utils', utils_module_path)

	# Add support for the `do` jinja tag
	jinja_env = Environment(extensions=['jinja2.ext.do'])

	# Fetch and render the map file for OS settings
	map_file = __salt__.cp.cache_file("salt://icinga2/map.jinja")
	map_tpl = jinja_env.from_string(open(map_file, 'r').read())
	map_mod = map_tpl.make_module(vars={'salt': __salt__})
	icinga2 = map_mod.icinga2

	if "conf" in icinga2:
		configuration = icinga2['conf']
	else:
		# Render the defaults.jinja file to get default configuration items
		defaults_file = __salt__.cp.cache_file("salt://icinga2/defaults.yaml")
		with open(defaults_file, 'r') as stream:
			configuration = yaml.load(stream)

	# Copy the constants dict defined in map.jinja
	icinga2_constants = icinga2['constants'].copy()

	# This defines in which file we want to store each object type
	object_file_map = {
		'apiuser': '/conf.d/api-users.conf',
		'icingaapplication': '/conf.d/app.conf',
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

	# Hold the object definitions (as a string) for each config file
	compiled_object_definitions = {k: '' for k in object_file_map.values()}

	for obj_type, obj_definitions in iter(sorted(configuration.iteritems())):
		for obj_name, obj_info in iter(sorted(obj_definitions.iteritems())):
			try:
				obj_function_name = 'icinga2_object_%s' % obj_type
				obj_function = getattr(utils, obj_function_name)
				definition = obj_function(obj_name, obj_info, utils.icinga2_globals, icinga2_constants) + "\n\n"

				if obj_info.get('template', False):
					object_file = object_file_map['template']
				elif obj_type in ['checkcommand', 'eventcommand'] and obj_info.get('global', False):
					object_file = '/zones.d/global-templates/commands.conf'

					if object_file not in compiled_object_definitions:
						compiled_object_definitions[object_file] = ''
				else:
					object_file = object_file_map[obj_type]

				compiled_object_definitions[object_file] += definition
			except KeyError as e:
				print('No function found for %s' % obj_type)
				print(e)

	# Create the states for each file
	for filename, definitions in compiled_object_definitions.iteritems():
		config[icinga2['conf_dir'] + filename] = {
			'file.managed': [
				{'user': 'root'},
				{'group': 'root'},
				{'mode': 644},
				{'contents': definitions},
				{'require': [
					{'pkg': 'icinga2_pkg'}
				]},
				{'watch_in': {
					'service': 'icinga2_reload'
				}}
			]
		}

	return config
