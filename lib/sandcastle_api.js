var sandcastle_output_stack = []
exports.api = {
	console: {
		log: function() {
			return sandcastle_output_stack.push(arguments);
		}
	},
	get_sandcastle_output_stack: function() {
		return sandcastle_output_stack
	},
	_require: function(dirname, module) {
		var path = require('path')
		var node_regexp = /^\w+$/
		var path_regexp = /^((\.|\.\.|\w+)\/)+\w+$/
		if (node_regexp.test(module)) {
			// if node module
			// TODO test if this is enabled module
		}
		if (path_regexp.test(module)) {
			// try to find the module
			// TODO check if module is not in directory
			var name_regexp = /\/(\w|\.)+$/;
			dirname = dirname.replace(name_regexp, '/');
			module = path.resolve(dirname + module);
		}
		return require(module)
	},
	__dirname: path.resolve(__dirname + '../../../../projects/')
};

