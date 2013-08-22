db = require '../lib/db'
auth = require '../lib/auth'
_ = require 'underscore'
fs = require 'fs'

{Project, User} = db.models

exports.boot = (app) ->
	app.post '/new', auth.user, (req, res) ->
		project = _.extend req.body,
			owner: req.user._id
		Project.create project, (err, project) ->
			User.findById req.user._id, (err, user) ->
				user.projects.push project._id
				path = [__dirname, '../projects', user._id, project._id].join '/'
				fs.mkdir path, '0777', (err) ->
					user.save()
					res.redirect '/user/projects'

	app.get '/:user/:project', auth.user, (req, res) ->
		User.findOne {nickname: req.params.user}, '_id', (err, user) ->
			return res.redirect '/user/projects' if err or !user
			Project.findOne({name: req.params.project, owner: user._id })
			.populate('owner')
			.populate('collaborators')
			.exec (err, project) ->
				res.render 'project', {project, loc:'projects'}
	app.post '/:id/delete', auth.user, (req, res) ->
		res.send {err: 'You do not have permissions to provide this action.', success: false}
		id = req.params.id
		Project.findById id, (err, project) ->
			User.find {$or: [{_id: {$in: project.collaborators}},{_id: project.owner}]}, (err, users) ->
				_.each users, (user) ->
					user.projects = user.projects.filter (p) -> p.toString() != id
					user.shared_projects = user.shared_projects.filter (p) -> p.toString() != id
					user.save()
				path = __dirname + '/../projects/' + req.user._id + '/' + project._id
				project.remove () ->
					fs.rmdir(path, callback)
					res.send success: true
	app.post '/:id/edit', auth.user, (req, res) ->
		id = req.params.id
		Project.update {_id: id}, {$set: req.body}, (err, project) ->
			res.redirect '/projects/'+ id


	app.post '/:id/add_collaborator', auth.user, (req, res) ->
		id = req.params.id
		User.findOne {email: req.body.email}, (err, user) ->
			console.log 'user', user
			return res.send({err: 'User not found', collaborator: null, success: false}) if (!user)
			user.shared_projects.push(id)
			user.save()
			Project.findById id, (err, project) ->
			 	project.collaborators.push(user._id)
			 	project.save () ->
					res.send({err: null, collaborator: user, success: true})

		# res.send({err: null, collaborator: user, success: true})
		# res.send({err: 'User not found', collaborator: null, success: false})

	app.get '/:user/:project/files', auth.user, (req, res) ->
		res.send 'success'
