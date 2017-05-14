#!py

import re


def attributes(attrs, global_vars, consts, indent=1):
	"""
	:attrs   dict
	:global_vars list
	:consts  dict
	"""

	def value_types(value):
		if re.search('^\d+\.?\d*[dhms]?$', value) or \
		   re.search('^(true|false)$', value) or \
		   re.search('^!?(host|service|user)\.', value) or \
		   re.search('^\{{2}.*\}{2}$', value):
			result = value
		else:
			result = None
			for constant in attributes_constants:
				if constant in dict_attrs:
					if re.search('^!?(%s)(\..+$|$)' % re.escape(constant), value):
						result = value
						break
				elif re.search('^!?%s$' % re.escape(constant), value):
					result = value
					break
				elif re.search('^".*"$', value):
					# Don't quote values that are already quoted
					result = value
					break

			if result is None:
				result = "\"%s\"" % value

		return result


	def attribute_types(attr):
		if re.search('^[a-zA-Z0-9_]+$', attr):
			result = attr
		else:
			result = "\"%s\"" % attr

		return result


	def parse(row):
		result = ''

		# scan function
		m = re.search('^\{{2}(.+)\}{2}$', str(row), re.S)
		if m:
			_1 = m.groups()[0]
			result += "{{%s}}" % _1
		else:
			# scan expression + function (function should contain expressions, but we donno parse it)
			m = re.search('^(.+)\s([\+-]|\*|\/|==|!=|&&|\|{2}|in)\s\{{2}(.+)\}{2}$', str(row))
			if m:
				_1, _2, _3 = m.groups()
				result += "%s %s {{%s}}" % (parse(_1), _2, _3)
			else:
				# scan expression
				m = re.search('^(.+)\s([\+-]|\*|\/|==|!=|&&|\|{2}|in)\s(.+)$', str(row))
				if m:
					_1, _2, _3 = m.groups()
					result += "%s %s %s" % (parse(_1), _2, parse(_3))
				else:
					m = re.search('^(.+)\((.*)$', str(row))
					if m:
						_1, _2 = m.groups()
						result += "%s(%s" % (_1, ', '.join(map(lambda x: parse(x.lstrip()), _2.split(','))))
					else:
						m = re.search('^(.*)\)$', str(row))
						if m:
							_1 = m.groups()[0]
							result += "%s)" % ', '.join(map(lambda x: parse(x.lstrip()), _1.split(',')))
						else:
							m = re.search('^\((.*)$', str(row))
							if m:
								_1 = m.groups()[0]
								result += "(%s" % parse(_1)
							else:
								result += value_types(str(row))

		return result.replace('" in "', ' in ')

	def process_list(items, indent=1):
		result = ''

		for value in items:
			if isinstance(value, dict):
				result += "\n%s{\n%s%s}, " % ("\t" * indent, process_dict(value, indent+1), "\t" * indent)
			elif isinstance(value, list):
				result += "[ %s], " % process_list(value, indent+1)
			elif value:
				result += "%s, " % parse(value)

		return result

	def process_dict(attrs, indent=1, level=3, prefix=None):
		result = ''

		if prefix is None:
			prefix = "\t" * indent

		for attr, value in attrs.items():
			if isinstance(value, dict):
				if not value:
					result = {
						1: "%s%s = {}\n" % (prefix, attribute_types(attr)),
						2: "%s[\"%s\"] = {}\n" % (prefix, attr),
					}.get(level, "%s%s = {}\n" % (prefix, attribute_types(attr)))
				else:
					result += {
						1: process_dict(value, indent, 2, "%s%s" % (prefix, attr)),
						2: "%s[\"%s\"] = {\n%s%s}\n" % (prefix, attr, process_dict(value, indent), "\t" * (indent-1)),
					}.get(level, "%s%s = {\n%s%s}\n" % (prefix, attribute_types(attr), process_dict(value, indent+1), "\t" * indent))
			elif isinstance(value, list):
				result += {
					2: "%s[\"%s\"] = [ %s]\n" % (prefix, attribute_types(attr), process_list(value))
				}.get(level, "%s%s = [ %s]\n" % (prefix, attribute_types(attr), process_list(value)))
			else:
				if value:
					if level > 1:
						if level == 3:
							result += "%s%s = %s\n" % (prefix, attribute_types(attr), parse(value))
						else:
							result += "%s[\"%s\"] = %s\n" % (prefix, attribute_types(attr), parse(value))
					else:
						result += "%s%s = %s\n" % (prefix, attr, parse(value))

		return result

	# global_vars and all keys of attrs dict must not quoted
	attributes_constants = global_vars + consts.keys() + ['name']
	# print('attributes_constants: %s' % attributes_constants)

	# select all attributes and constants if their value is a dict
	dict_attrs  = [key for key, val in attrs.iteritems() if isinstance(val, dict)]
	dict_attrs += [key for key, val in consts.iteritems() if isinstance(val, dict)]

	# initialize returned configuration
	config = ''

	for attr, value in attrs.items():
		if re.search('^(assign|ignore) where$', attr):
			for x in value:
				config += "%s%s %s\n" % ("\t" * indent, attr, parse(x))
		else:
			if isinstance(value, dict):
				if attr == 'vars':
					config += process_dict(value, indent+1, 1, "%s%s." % ("\t" * indent, attr))
				else:
					config += "%s%s = {\n%s%s}\n" % ("\t" * indent, attr, process_dict(value, indent+1), "\t" * indent)
			elif isinstance(value, list):
				config += "%s%s = [ %s]\n" % ("\t" * indent, attr, process_list(value))
			else:
				config += "%s%s = %s\n" % ("\t" * indent, attr, parse(value))

	return config


def icinga2_attributes(args, global_vars=[], constants={}):
	"""
	Called from the object template to render icinga2 object properties

	:args is a list
		_attrs =
	"""

	if len(args) > 1:
		indent = args[1]
	else:
		indent = 0

	if len(args) > 2:
		global_vars += args[2]

	if len(args) > 3:
		constants.update(args[3])

	return attributes(args[0], global_vars, constants, indent)


def icinga2_object(p, icinga2_globals, icinga2_constants):
	"""
	Render the properties and attributes into an Icinga 2 object definition

	Args:
		p: properties dict
			- apply
			- apply_target
			- assign
			- attrs
			- attrs_list
			- ignore
			- import
			- object_name
			- object_type
			- prefix
			- template

	Returns:
		string
	"""

	apply_       = p.get('apply', False)
	apply_target = p.get('apply_target', None)
	assign       = p.get('assign', [])
	attrs        = p.get('attrs', {})
	attrs_list   = p.get('attrs_list', [])
	ignore       = p.get('ignore', [])
	import_      = p.get('import', [])
	object_name  = p.get('object_name')
	object_type  = p.get('object_type')
	prefix       = p.get('prefix', False)
	template     = p.get('template', False)

	if (object_type == apply_target):
		raise Exception('The object type must be different from the apply target')

	_attrs = attrs.copy()
	_attrs.update({'assign where': assign, 'ignore where': ignore})

	# content will be a string with the Icinga2 config definition
	content = ""

	if isinstance(apply_, basestring):
		content += "apply %s" % object_type

		if prefix:
			if object_name in icinga2_constants:
				content += " %s" % object_name
			else:
				content += " \"%s\"" % object_name

		content += " for (%s) to %s {\n" % (apply_, apply_target)
	else:
		if apply_:
			content += "apply"
		else:
			if template:
				content += "template"
			else:
				content += "object"

		content += " %s" % object_type

		if object_name in icinga2_constants.keys():
			content += " %s" % object_name
		else:
			content += " \"%s\" " % object_name

		if apply_ and apply_target:
			content += "to %s" % apply_target

		content += " {\n"

	for template in import_:
		content += "	import \"%s\"\n" % template

	if import_:
		content += "\n"

	if isinstance(apply_, basestring):
		m = re.search('^([A-Za-z_]+)\s+in\s+.+$', apply_)
		if m:
			_1 = m.groups()[0]
			content += icinga2_attributes([_attrs, 1, attrs_list, {_1: {}}], icinga2_globals, icinga2_constants)
		else:
			m = re.search('^([A-Za-z_]+)\s+=>\s+([A-Za-z_]+)\s+in\s+.+$', apply_)
			if m:
				_1, _2 = m.groups()
				content += icinga2_attributes([_attrs, 1, attrs_list + [_1], {_2: {}}], icinga2_globals, icinga2_constants)
	else:
		content += icinga2_attributes([_attrs, 1, attrs_list], icinga2_globals, icinga2_constants)

	content += '}'

	return content


def icinga2_object_apiuser(name, p, icinga2_globals, icinga2_constants):
	"""
	Render an Icinga 2 API user object definition

	Args:
		apiuser_name: string - the name for the user
		p: properties dict
			- client_cn: string
			- password: string
			- permissions: list
	"""
	# compose the attributes
	attrs = {
		'password': p.get('password', None),
		'client_cn': p.get('client_cn', None),
		'permissions': p.get('permissions'),
	}

	return icinga2.icinga2_object({
		'object_name': name,
		'object_type': 'ApiUser',
		'attrs': dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list': attrs.keys(),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_checkcommand(name, p, icinga2_globals, icinga2_constants):
	# compose the attributes
	attrs = {
		'command':   p.get('command', None),
		'env':       p.get('env', None),
		'timeout':   p.get('timeout', None),
		'arguments': p.get('arguments', None),
		'vars':      p.get('vars', None),
	}

	return icinga2_object({
		'object_name': name,
		'object_type': 'CheckCommand',
		'template':    p.get('template', False),
		'import':      p.get('import', ['plugin-check-command']),
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_dependency(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'parent_host_name':      p.get('parent_host_name', None),
		'parent_service_name':   p.get('parent_service_name', None),
		'child_host_name':       p.get('child_host_name', None),
		'child_service_name':    p.get('child_service_name', None),
		'disable_checks':        p.get('disable_checks', None),
		'disable_notifications': p.get('disable_notifications', None),
		'ignore_soft_states':    p.get('ignore_soft_states', None),
		'period':                p.get('period', None),
		'states':                p.get('states', None),
	}

	# create object
	return icinga2_object({
		'object_name':  name,
		'object_type':  'Dependency',
		'import':       p.get('import', []),
		'template':     p.get('template', False),
		'attrs':        dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':   attrs.keys(),
		'apply':        p.get('apply', False),
		'prefix':       p.get('prefix', False),
		'apply_target': p.get('apply_target', 'Host'),
		'assign':       p.get('assign', []),
		'ignore':       p.get('ignore', []),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_endpoint(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'host':         p.get('host', None),
		'port':         p.get('port', None),
		'log_duration': p.get('log_duration', None),
	}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'Endpoint',
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_eventcommand(name, p, icinga2_globals, icinga2_constants):
	# compose the attributes
	attrs = {
		'command':   p.get('command', None),
		'env':       p.get('env', None),
		'timeout':   p.get('timeout', None),
		'arguments': p.get('arguments', None),
		'vars':      p.get('vars', None),
	}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'EventCommand',
		'import':      p.get('import', ['plugin-event-command']),
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_host(name, p, icinga2_globals, icinga2_constants):
	"""
	Render an Icinga 2 host definition

	Args:
		host_name: string
		p: properties dict
			- action_url
			- address
			- address6
			- check_command
			- check_interval
			- check_period
			- check_timeout
			- command_endpoint
			- display_name
			- enable_active_checks
			- enable_event_handler
			- enable_flapping
			- enable_notifications
			- enable_passive_checks
			- enable_perfdata
			- event_command
			- flapping_threshold
			- groups
			- icon_image
			- icon_image_alt
			- import
			- max_check_attempts
			- notes
			- notes_url
			- retry_interval
			- template
			- vars
			- volatile
			- zone
	"""
	attrs = {
		'action_url': p.get('action_url', None),
		'address': p.get('address', None),
		'address6': p.get('address6', None),
		'check_command': p.get('check_command', None),
		'check_interval': p.get('check_interval', None),
		'check_period': p.get('check_period', None),
		'check_timeout': p.get('check_timeout', None),
		'command_endpoint': p.get('command_endpoint', None),
		'display_name': p.get('display_name', None),
		'enable_active_checks': p.get('enable_active_checks', None),
		'enable_event_handler': p.get('enable_event_handler', None),
		'enable_flapping': p.get('enable_flapping', None),
		'enable_notifications': p.get('enable_notifications', None),
		'enable_passive_checks': p.get('enable_passive_checks', None),
		'enable_perfdata': p.get('enable_perfdata', None),
		'event_command': p.get('event_command', None),
		'flapping_threshold': p.get('flapping_threshold', None),
		'groups': p.get('groups', None),
		'icon_image': p.get('icon_image', None),
		'icon_image_alt': p.get('icon_image_alt', None),
		'max_check_attempts': p.get('max_check_attempts', None),
		'notes': p.get('notes', None),
		'notes_url': p.get('notes_url', None),
		'retry_interval': p.get('retry_interval', None),
		'vars': p.get('vars', None),
		'volatile': p.get('volatile', None),
		'zone': p.get('zone', None),
	}

	return icinga2_object({
		'attrs': dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list': attrs.keys(),
		'import': p.get('import', []),
		'object_name': name,
		'object_type': 'Host',
		'template': p.get('template', False),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_hostgroup(name, p, icinga2_globals, icinga2_constants):
	# compose the attributes
	attrs = {
		'display_name': p.get('display_name', None),
		'groups':       p.get('groups', None),
	}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'HostGroup',
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
		'assign':      p.get('assign', []),
		'ignore':      p.get('ignore', []),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_notification(name, p, icinga2_globals, icinga2_constants):
	# compose attributes
	attrs = {
		'host_name':    p.get('host_name', None),
		'service_name': p.get('service_name', None),
		'users':        p.get('users', None),
		'user_groups':  p.get('user_groups', None),
		'times':        p.get('times', None),
		'command':      p.get('command', None),
		'interval':     p.get('interval', None),
		'period':       p.get('period', None),
		'zone':         p.get('zone', None),
		'types':        p.get('types', None),
		'states':       p.get('states', None),
		'vars':         p.get('vars', None),
	}

	# create object
	return icinga2_object({
		'object_name':  name,
		'object_type':  'Notification',
		'import':       p.get('import', []),
		'template':     p.get('template', False),
		'attrs':        dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':   attrs.keys(),
		'apply':        p.get('apply', False),
		'prefix':       p.get('prefix', False),
		'apply_target': p.get('apply_target', None),
		'assign':       p.get('assign', []),
		'ignore':       p.get('ignore', []),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_notificationcommand(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'command':   p.get('command', None),
		'env':       p.get('env', None),
		'timeout':   p.get('timeout', None),
		'arguments': p.get('arguments', None),
		'vars':      p.get('vars', None),
	}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'NotificationCommand',
		'template':    p.get('template', False),
		'import':      p.get('import', ['plugin-notification-command']),
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_scheduleddowntime(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'host_name':    p.get('host_name', None),
		'service_name': p.get('service_name', None),
		'author':       p.get('author', None),
		'comment':      p.get('comment', None),
		'fixed':        p.get('fixed', None),
		'duration':     p.get('duration', None),
		'ranges':       p.get('ranges', None),
	}

	# create object
	return icinga2_object({
		'object_name':  name,
		'object_type':  'ScheduledDowntime',
		'attrs':        dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':   attrs.keys(),
		'apply':        p.get('apply', False),
		'prefix':       p.get('prefix', False),
		'apply_target': p.get('apply_target', 'Host'),
		'assign':       p.get('assign', []),
		'ignore':       p.get('ignore', []),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_service(name, p, icinga2_globals, icinga2_constants):
	"""
	Render an Icinga 2 service object definition

	Args:
		service_name: string
		p: properties dict
			- action_url
			- apply
			- assign
			- check_command
			- check_interval
			- check_period
			- check_timeout
			- command_endpoint
			- display_name
			- enable_active_checks
			- enable_event_handler
			- enable_flapping
			- enable_notifications
			- enable_passive_checks
			- enable_perfdata
			- event_command
			- flapping_threshold
			- groups
			- host_name
			- icon_image
			- icon_image_alt
			- ignore
			- import
			- max_check_attempts
			- notes
			- notes_url
			- prefix
			- retry_interval
			- template
			- vars
			- volatile
			- zone
	"""

	attrs = {
		'action_url': p.get('action_url', None),
		'check_command': p.get('check_command', None),
		'check_interval': p.get('check_interval', None),
		'check_period': p.get('check_period', None),
		'check_timeout': p.get('check_timeout', None),
		'command_endpoint': p.get('command_endpoint', None),
		'display_name': p.get('display_name', None),
		'enable_active_checks': p.get('enable_active_checks', None),
		'enable_event_handler': p.get('enable_event_handler', None),
		'enable_flapping': p.get('enable_flapping', None),
		'enable_notifications': p.get('enable_notifications', None),
		'enable_passive_checks': p.get('enable_passive_checks', None),
		'enable_perfdata': p.get('enable_perfdata', None),
		'event_command': p.get('event_command', None),
		'flapping_threshold': p.get('flapping_threshold', None),
		'groups': p.get('groups', None),
		'host_name': p.get('host_name', None),
		'icon_image': p.get('icon_image', None),
		'icon_image_alt': p.get('icon_image_alt', None),
		'max_check_attempts': p.get('max_check_attempts', None),
		'notes': p.get('notes', None),
		'notes_url': p.get('notes_url', None),
		'retry_interval': p.get('retry_interval', None),
		'vars': p.get('vars', None),
		'volatile': p.get('volatile', None),
		'zone': p.get('zone', None),
	}

	return icinga2_object({
		'apply':        p.get('apply', False),
		'apply_target': 'Host',
		'assign':       p.get('assign', []),
		'attrs':        dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':   attrs.keys(),
		'ignore':       p.get('ignore', []),
		'import':       p.get('import', []),
		'object_name':  name,
		'object_type':  'Service',
		'prefix':       p.get('prefix', False),
		'template':     p.get('template', False),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_servicegroup(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'display_name': p.get('display_name', None),
		'groups':       p.get('groups', None),
	}

	# create object
	return icinga2_object({
		'object_name':  name,
		'object_type':  'ServiceGroup',
		'import':       p.get('import', []),
		'template':     p.get('template', False),
		'attrs':        dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':   attrs.keys(),
		'assign':       p.get('assign', []),
		'ignore':       p.get('ignore', []),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_timeperiod(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'display_name':    p.get('display_name', None),
		'ranges':          p.get('ranges', None),
		'prefer_includes': p.get('prefer_includes', None),
		'excludes':        p.get('excludes', None),
		'includes':        p.get('includes', None),
	}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'TimePeriod',
		'template':    p.get('template', False),
		'import':      p.get('import', ['legacy-timeperiod']),
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_user(name, p, icinga2_globals, icinga2_constants):
	"""
	Render an Icinga 2 user object definition

	Args:
		user_name: string
		p: properties dict
			- display_name
			- email
			- enable_notifications
			- groups
			- import
			- pager
			- period
			- states
			- template
			- types
			- vars
	"""
	attrs = {
		'display_name': p.get('display_name', None),
		'email': p.get('email', None),
		'enable_notifications': p.get('enable_notifications', None),
		'groups': p.get('groups', None),
		'pager': p.get('pager', None),
		'period': p.get('period', None),
		'states': p.get('states', None),
		'types': p.get('types', None),
		'vars': p.get('vars', None),
	}

	return icinga2_object({
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
		'import':      p.get('import', []),
		'object_name': name,
		'object_type': 'User',
		'template':    p.get('template', False),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_usergroup(name, p, icinga2_globals, icinga2_constants):
	attrs = {
		'display_name': p.get('display_name', None),
		'groups':       p.get('groups', []),
	}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'UserGroup',
		'import':      p.get('import', []),
		'template':    p.get('template', False),
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
		'assign':      p.get('assign', []),
		'ignore':      p.get('ignore', []),
	}, icinga2_globals, icinga2_constants)


def icinga2_object_zone(name, p, icinga2_globals, icinga2_constants):
	if p.get('global', False):
		attrs = {
			'global': p.get('global'),
		}
	else:
		attrs = {
			'endpoints': p.get('endpoints', None),
			'parent':    p.get('parent', None),
		}

	# create object
	return icinga2_object({
		'object_name': name,
		'object_type': 'Zone',
		'attrs':       dict((x, y) for x, y in attrs.iteritems() if y is not None),
		'attrs_list':  attrs.keys(),
	}, icinga2_globals, icinga2_constants)