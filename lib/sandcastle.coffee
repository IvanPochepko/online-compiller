SandCastle = require('sandcastle').SandCastle

exports.runJS = (text, cb) ->
	sandcastle = new SandCastle
		api: __dirname + '/sandcastle_api.js'
	text = "exports.main = function() {" + text + "\nexit(get_sandcastle_output_stack())}"
	console.log text

	script = sandcastle.createScript(text)
	script.on 'exit', (err, output) ->
		console.log('output: ',output, err)
		console.log '-----------'

		cb && cb(err, output)
	script.run()

