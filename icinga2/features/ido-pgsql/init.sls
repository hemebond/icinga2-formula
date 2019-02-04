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


	fsid  = 'ido_pgsql'                                     # feature state id
	fname = 'ido-pgsql'                                     # feature name
	fconf = icinga2['features'][fname]                      # feature configuration
	ffile = 'ido-pgsql.conf'                                # feature configuration file
	ftype = 'IdoPgsqlConnection'                            # feature object type
	fschm = '/usr/share/icinga2-ido-pgsql/schema/pgsql.sql' # feature schema file
	fpkg  = icinga2['feature_packages'][fname]              # feature package name


	config['icinga2_' + fsid + '_pkg'] = {
		'pkg.installed': [
			{'name': icinga2['feature_packages'][fname]},
			{'watch_in': [
				{'service': 'icinga2_service'},
			]}
		]
	}


	config[icinga2['conf_dir'] + '/features-available/' + ffile] = {
		'file.managed': [
			{'user': 'root'},
			{'group': 'root'},
			{'mode': 644},
			{'contents': 'library "db_ido_pgsql"\n\n' + utils.icinga2_object(
				{
					"object_name": fname,
					"object_type": ftype,
					"attrs": fconf,
				},
				utils.icinga2_globals,
				icinga2['constants'])
			},
			{'require': [
				{'pkg': 'icinga2_pkg'}
			]},
			{'watch_in': [
				{'service': 'icinga2_service'}
			]}
		]
	}


	config['icinga2_' + fsid + '_enable'] = {
		'cmd.run': [
			{'name': 'icinga2 feature enable ' + fname},
			{'watch_in': [
				{'service': 'icinga2_service'}
			]},
			{'unless': 'icinga2 feature list | grep Enabled | grep -w ' + fname}
		]
	}


	config['icinga2_' + fsid + '_schema'] = {
		'cmd.run': [
			{'name': 'psql -v ON_ERROR_STOP=1 --host={} --dbname={} --username={} < {}'.format(fconf['host'],
			                                                                                   fconf['name'],
			                                                                                   fconf['user'],
			                                                                                   fschm)},
			{'env': [
				{'PGPASSWORD': fconf['password']}
			]},
			{'unless': 'PGPASSWORD={} psql --host={} --dbname={} --username={} -c "SELECT * FROM icinga_dbversion;"'.format(fconf['password'],
			                                                                                                                fconf['host'],
			                                                                                                                fconf['name'],
			                                                                                                                fconf['user'])},
			{'require': [
				{'pkg': 'icinga2_' + fsid + '_pkg'}
			]}
		]
	}


	return config
