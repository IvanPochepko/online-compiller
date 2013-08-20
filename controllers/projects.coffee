db = require '../lib/db'
auth = require '../lib/auth'
_ = require 'underscore'

{Project, User} = db.models

exports.boot = (app) ->
	app.post '/new', auth.user, (req, res) ->
		project = _.extend req.body,
			owner: req.user._id
		Project.create project, (err, project) ->
			User.findById req.user._id, (err, user) ->
				user.projects.push project._id
				user.save()
				res.redirect '/user/projects'


	app.get '/:id', auth.user, (req, res) ->
		Project.findOne({_id: req.params.id})
		.populate('owner')
		.populate('collaborators')
		.exec (err, project) ->
			res.render 'project', {project, loc:'projects'}
	app.post '/:id/delete', auth.user, (req, res) ->
		id = req.params.id
		Project.findById id, (err, project) ->
			User.find {$or: [{_id: {$in: project.collaborators}},{_id: project.owner}]}, (err, users) ->
				_.each users, (user) ->
					user.projects = user.projects.filter (p) -> p.toString() != id
					user.shared_projects = user.shared_projects.filter (p) -> p.toString() != id
					user.save()
				project.remove () ->
					res.send('success')
	app.post '/:id/edit', auth.user, (req, res) ->
		id = req.params.id
		Project.update {_id: id}, {$set: req.body}, (err, project) ->
			res.redirect '/projects/'+ id


	app.post '/:id/add_collaborator', auth.user, (req, res) ->
		id = req.params.id
		User.findOne {email: req.body.email}, (err, user) ->
			console.log 'user', user
			res.send({err: 'User not found', collaborator: null, success: false}) if (!user)
			user.shared_projects.push(id)
			user.save()
			Project.findById id, (err, project) ->
			 	project.collaborators.push(user._id)
			 	project.save () ->
					res.send({err: null, collaborator: user, success: true})



		# res.send({err: null, collaborator: user, success: true})
		# res.send({err: 'User not found', collaborator: null, success: false})

