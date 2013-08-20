db = require '../lib/db'
auth = require '../lib/auth'
_ = require 'underscore'

{Project, User} = db.models

exports.boot = (app) ->
	app.get '/projects', auth.user, (req, res) ->
		User.findOne({_id: req.user._id})
		.populate('projects')
		.populate('shared_projects')
		.exec (err, user) ->
			console.log 'user', user
			return res.redirect '/' if err
			res.render 'projects', {title: 'Onlile JS Compiller', projects: user.projects, shared_projects: user.shared_projects, loc:'projects'}

