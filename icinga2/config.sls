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
	osmap_file = __salt__.cp.cache_file("salt://icinga2/map.jinja")
	osmap_tpl = jinja_env.from_string(open(osmap_file, 'r').read())
	osmap_mod = osmap_tpl.make_module(vars={'salt': __salt__})
	icinga2 = osmap_mod.icinga2

	# Prefix each key in the constants dict with "const "
	prefixed_constants = {'const {}'.format(k):v for k, v in icinga2['constants'].iteritems()}

	config[icinga2['conf_dir'] + '/constants.conf'] = {
		'file.managed': [
			{'user': icinga2['user']},
			{'group': icinga2['group']},
			{'mode': 600},
			{'contents': m.icinga2_attributes([prefixed_constants])}
		]
	}

	config[icinga2['conf_dir'] + '/icinga2.conf'] = {
		'file.managed': [
			{'user': icinga2['user']},
			{'group': icinga2['group']},
			{'mode': 600},
			{'source': 'salt://icinga2/files/icinga2.conf.jinja'},
			{'template': 'jinja'},
			{'context': {
				'icinga2': icinga2
			}},
			{'watch_in': {
				'service': 'icinga2'
			}}
		]
	}

	return config
