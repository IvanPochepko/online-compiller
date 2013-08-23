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
			owned_projects = user.projects.length
			projects = user.projects.concat user.shared_projects
			User.populate projects, {path: 'owner', model: 'User'}, (err, projects) ->
				user.projects = projects.splice 0, owned_projects
				user.shared_projects = projects
				return res.redirect '/' if err
				res.render 'projects', {title: 'Onlile JS Compiller', projects: user.projects, shared_projects: user.shared_projects, loc:'projects'}
