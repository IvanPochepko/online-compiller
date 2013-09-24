SandCastle = require('sandcastle').SandCastle

exports.createSandbox = (project, cb) ->
	# individual sandbox for built project
	# TODO set individual api file
	sandcastle = new SandCastle
		api: __dirname + '/sandcastle_api.js'
	sandcastle.runJS = (file, text, cb) ->
		text = "exports.main = function() {\n\
			__dirname = __dirname + '<file_path>'; \n\
			require = function(module){return _require(__dirname, module)}; \n\
		" + text + "\n exit(get_sandcastle_output_stack())}"
		text = text.replace '<file_path>', '/' + project._id + file.path + file.name
		script = @createScript(text)
		script.on 'exit', (err, output) ->
			sandcastle.kill()
			cb && cb(err, output)
		script.run()
	sandcastle.sandboxReady () ->
		cb and cb sandcastle
