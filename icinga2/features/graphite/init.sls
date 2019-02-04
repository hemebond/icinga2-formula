#!py

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


	# config['include'] = [
	# 	'icinga2'
	# ]

	contents = '\n\n'.join([
		"library \"perfdata\"",
		utils.icinga2_object({
			"object_name": "graphite",
			"object_type": "GraphiteWriter",
			"attrs": icinga2['features'].get('graphite', {}),
		},
		utils.icinga2_globals,
		icinga2['constants'])
	])

	config[icinga2['conf_dir'] + '/features-available/graphite.conf'] = {
		'file.managed': [
			{'user': 'root'},
			{'group': 'root'},
			{'mode': 644},
			{'contents': contents},
			{'require': [
				{'pkg': 'icinga2_pkg'}
			]},
			{'watch_in': [
				{'service': 'icinga2_service'}
			]}
		]
	}

	config['icinga2_graphite_enable'] = {
		'cmd.run': [
			{'name': 'icinga2 feature enable graphite'},
			{'watch_in': [
				{'service': 'icinga2_service'}
			]},
			{'unless': 'icinga2 feature list | grep Enabled | grep -w graphite'}
		]
	}

	return config
