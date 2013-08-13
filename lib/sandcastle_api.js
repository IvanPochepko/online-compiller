var sandcastle_output_stack = []
exports.api = {
	console: {
		log: function() {
			console.log('console log... ', arguments);
			return sandcastle_output_stack.push(arguments);
		}
	},
	get_sandcastle_output_stack: function() {
		return sandcastle_output_stack
	}
};

