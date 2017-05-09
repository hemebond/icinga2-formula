#!py

import imp
from jinja2 import Environment, Template

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

	# Prefix each key in the constants dict with "const "
	prefixed_constants = {'const {}'.format(k):v for k, v in osmap['constants'].iteritems()}

	config[osmap['conf_dir'] + '/constants.conf'] = {
		'file.managed': [
			{'user': osmap['user']},
			{'group': osmap['group']},
			{'mode': 600},
			{'contents': m.icinga2_attributes([prefixed_constants])}
		]
	}

	config[osmap['conf_dir'] + '/icinga2.conf'] = {
		'file.managed': [
			{'user': osmap['user']},
			{'group': osmap['group']},
			{'mode': 600},
			{'source': 'salt://icinga2/files/icinga2.conf.jinja'},
			{'template': 'jinja'},
			{'context': {
				'icinga2': osmap
			}},
			{'watch_in': {
				'service': 'icinga2'
			}}
		]
	}

	return config
