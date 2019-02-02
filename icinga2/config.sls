#!py

from textwrap import dedent
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

	# Prefix each key in the constants dict with "const "
	prefixed_constants = {'const {}'.format(k):v for k, v in icinga2['constants'].iteritems()}

	config[icinga2['conf_dir'] + '/constants.conf'] = {
		'file.managed': [
			{'user': 'root'},
			{'group': 'root'},
			{'mode': 644},
			{'contents': utils.icinga2_attributes([prefixed_constants], utils.icinga2_globals)},
			{'require': [
				{'pkg': 'icinga2_pkg'}
			]},
			{'watch_in': [
				{'service': 'icinga2_service'}
			]}
		]
	}

	config[icinga2['conf_dir'] + '/icinga2.conf'] = {
		'file.managed': [
			{'user': 'root'},
			{'group': 'root'},
			{'mode': 644},
			{'source': 'salt://icinga2/files/icinga2.conf.jinja'},
			{'template': 'jinja'},
			{'context': {
				'icinga2': icinga2
			}},
			{'require': [
				{'pkg': 'icinga2_pkg'}
			]},
			{'watch_in': {
				'service': 'icinga2_service'
			}}
		]
	}

	if icinga2.viewkeys() & {'RunAsUser', 'RunAsGroup'}:
		init_conf_contents = dedent('''\
		/**
		 * This file is read by Icinga 2 before the main
		 * configuration file (icinga2.conf) is processed.
		 */

		''')

		init_conf_contents += utils.icinga2_attributes(
			[
				{
					'const RunAsUser': icinga2['RunAsUser'],
					'const RunAsGroup': icinga2['RunAsGroup']
				}
			],
			utils.icinga2_globals
		)

		config[icinga2['conf_dir'] + '/init.conf'] = {
			'file.managed': [
				{'user': 'root'},
				{'group': 'root'},
				{'mode': 644},
				{'contents': init_conf_contents},
				{'template': 'jinja'},
				{'require': [
					{'pkg': 'icinga2_pkg'}
				]},
				{'watch_in': {
					'service': 'icinga2_service'
				}}
			]
		}

	return config
