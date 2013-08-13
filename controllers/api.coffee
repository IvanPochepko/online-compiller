sandcastle = require '../lib/sandcastle'

exports.boot = (app) ->
	app.post '/runjs', (req, res) ->
		text = req.body.text
		sandcastle.runJS text, (err, result) ->
			res.send {err, result}

