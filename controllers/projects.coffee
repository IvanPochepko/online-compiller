db = require '../lib/db'
auth = require '../lib/auth'
_ = require 'underscore'
fs = require 'fs'
exec = require('child_process').exec

{Project, User} = db.models

exports.boot = (app) ->
	app.post '/new', auth.user, (req, res) ->
		project = _.extend req.body,
			owner: req.user._id
		Project.findOne {owner: req.user._id, name: project.name}, (err, p) ->
			return 	res.redirect '/user/projects' if p
			Project.create project, (err, project) ->
				User.findById req.user._id, (err, user) ->
					user.projects.push project._id
					#path = [__dirname, '../projects', user._id, project._id].join '/'
					#fs.mkdir path, '0777', (err) ->
					user.save()
					res.redirect '/user/projects'

	app.get '/:id/files.json', auth.user, (req, res) ->
		Project.findById(req.params.id)
		.populate('files')
		.exec (err, project) ->
			res.send project

	app.get '/:user/:project', auth.user, (req, res) ->
		User.findOne {nickname: req.params.user}, '_id', (err, user) ->
			return res.redirect '/user/projects' if err or !user
			Project.findOne({name: req.params.project, owner: user._id })
			.populate('owner')
			.populate('collaborators')
			.exec (err, project) ->
				res.render 'project', {project, loc:'projects'}
	app.post '/:id/delete', auth.user, (req, res) ->
		id = req.params.id
		Project.findById id, (err, project) ->
			res.send {err: 'You do not have permissions to provide this action.', success: false} unless req.user._id.toString() is project.owner.toString()
			User.find {$or: [{_id: {$in: project.collaborators}},{_id: project.owner}]}, (err, users) ->
				return res.redirect '/user/projects' if err
				_.each users, (user) ->
					user.projects = user.projects.filter (p) -> p.toString() != id
					user.shared_projects = user.shared_projects.filter (p) -> p.toString() != id
					user.save()
				path = __dirname + '/../projects/' + req.user._id + '/' + project._id
				project.remove () ->
					removeDirectory path, (err, out) ->
						console.log err, out
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
		User.findOne {nickname: req.params.user}, (err, user) ->
			return res.redirect '/user/projects' if err or !user
			Project.findOne {owner: user._id, name: req.params.project}, (err, project) ->
				res.render 'project_files', {project}


removeDirectory = (path, cb) ->
	exec 'rm -rf ' + path, (err, out) ->
		cb and cb err, out
