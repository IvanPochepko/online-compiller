db = require '../lib/db'
auth = require '../lib/auth'
_ = require 'underscore'
fs = require 'fs'
exec = require('child_process').exec
sandcastle = require '../lib/sandcastle'
filesystem = require '../lib/filesystem'


{Project, User, File} = db.models

exports.boot = (app) ->
	app.post '/new', auth.user, (req, res) ->
		return res.send {success: false, errCode: 400, err: 'Project not specified', file: null} unless req.body.project
		Project.findById(req.body.project)
		.populate('files')
		.populate('owner')
		.populate('collaborators')
		.exec (err, project) ->
			return res.send {success: false, errCode: 500, err: 'Project not found', file: null} if err or !project
			# Check permission
			users = project.collaborators.concat project.owner
			found = _.some users, (user) -> user._id.toString() == req.user._id
			return res.send {success: false, errCode: 401, err: 'No permissions for this action', file: null} unless found
			# check if file with such name and path already exists
			found = _.some project.files, (file) -> file.path is req.body.path and file.name is req.body.name
			return res.send {success: false, errCode: 400, err: 'File already exists', file: null} if found
			# now everything is ok, and we can create file
			#path = [__dirname, '../projects', project.owner._id, project._id].join('/') + req.body.path
			file = new File
				name: req.body.name
				created_at: new Date()
				is_dir: req.body.is_dir is 'true'
				path: req.body.path
			file.save (err) ->
				project.files.push file
				project.save (err) ->
#					if file.is_dir
#						# creating file
#						fs.mkdir path + file.name, '0777', (err) -> done err, file
#					else
#						# creating folder
#						fs.open path + file.name, 'w', '0777', (err, fd) ->
#							return done err, null if err
#							fs.close fd, (err) ->
					done err, file
		done = (err, file) ->
			data = err and {errCode: 500, err, success: false, file: null} or {success: true, file}
			res.send data
	app.post '/rename', auth.user, (req, res) ->
		data = req.body
		missed = !data.project and 'Project' or !data.file and 'File' or !data.name and 'New name' or null
		return res.send {success: false, errCode: 400, err: missed + ' not specified', file: null} if missed
		Project.findById(data.project)
		.populate('files')
		.populate('owner')
		.populate('collaborators')
		.exec (err, project) ->
			return res.send {success: false, errCode: 500, err: 'Project not found', file: null} if err or !project
			# Check permission
			users = project.collaborators.concat project.owner
			found = _.some users, (user) -> user._id.toString() == req.user._id
			return res.send {success: false, errCode: 401, err: 'No permissions for this action', file: null} unless found
			# check if file with such name and path already exists
			found = _.some project.files, (file) -> file.path is data.path and file.name is data.name and file._id.toString() isnt data.file
			return res.send {success: false, errCode: 400, err: 'File with this name already exists', file: null} if found
			# check if file not exist
			file = _.find project.files, (file) -> file._id.toString() == data.file
			return res.send {success: false, errCode: 400, err: 'File not found', file: null} unless file
			# now everything is ok, and we can rename file
			regexp_text = ('^' + file.path + file.name + '/').replace(/\//g, '\\/')
			new_path = file.path + data.name + '/'
			file.name = data.name
			file.save () ->
				res.send {success: true, file: file}
				if file.is_dir
					regexp = new RegExp(regexp_text)
					children = project.files.filter (f) -> regexp.test f.path
					console.log children
					children.forEach (child) ->
						child.path = child.path.replace regexp, new_path
						child.save()


	app.post '/remove', auth.user, (req, res) ->
		data = req.body
		missed = !data.project and 'Project' or !data.file and 'File' or null
		return res.send {success: false, errCode: 400, err: missed + ' not specified'} if missed
		Project.findById(data.project)
		.populate('files')
		.populate('owner')
		.populate('collaborators')
		.exec (err, project) ->
			return res.send {success: false, errCode: 500, err: 'Project not found', file: null} if err or !project
			# Check permission
			users = project.collaborators.concat project.owner
			found = _.some users, (user) -> user._id.toString() == req.user._id
			return res.send {success: false, errCode: 401, err: 'No permissions for this action', file: null} unless found
			# check if file not exist
			file = _.find project.files, (file) -> file._id.toString() == data.file
			return res.send {success: false, errCode: 400, err: 'File not found', file: null} unless file
			# now everything is ok, and we can remove file
			#path = [__dirname, '../projects', project.owner._id, project._id].join('/') + file.path + file.name
			#command = 'rm -rf ' + path
			ids = [file._id]
			regExp = new RegExp '^' + file.path + file.name + '/.*$'
			project.files = project.files.filter (file) ->
				passed = !(regExp.test file.path) and file._id.toString() isnt data.file
				ids.push file._id unless passed
				passed
			project.save () ->
				File.remove {_id: {$in: ids}}, (err) ->
					#exec command, (err, stdout) ->
					res.send {success: true}
	app.post '/run', auth.user, (req, res) ->
		data = req.body
		missed = !data.project and 'Project' or !data.file and 'File' or null
		return res.send {success: false, errCode: 400, err: missed + ' not specified'} if missed
		Project.findById(data.project)
		.populate('files')
		.populate('owner')
		.populate('collaborators')
		.exec (err, project) ->
			return res.send {success: false, errCode: 500, err: 'Project not found', file: null} if err or !project
			# Check permission
			users = project.collaborators.concat project.owner
			found = _.some users, (user) -> user._id.toString() == req.user._id
			return res.send {success: false, errCode: 401, err: 'No permissions for this action', file: null} unless found
			# check if file not exist
			file = _.find project.files, (file) -> file._id.toString() == data.file
			return res.send {success: false, errCode: 400, err: 'File not found', file: null} unless file
			# now everything is ok, and we can run file
			console.log '-----------------------'
			console.log 'Attempt to run file'
			console.log 'Actor: ' + req.user.firstName + ' ' + req.user.lastName
			console.log 'Project: ' + project.name
			console.log 'File: ' + file.path + file.name
			console.log '-----------------------'
			# TODO notify client with req.flash that project starts building
			filesystem.buildProject project, () ->
			    console.log 'project built'
				# TODO notify client with req.flash that project is built and now running
				filesystem.getFile project, file, (err, text) ->
					sandcastle.createSandbox project, (sandbox) ->
						sandbox.runJS file, text, (err, result) ->
							# TODO send results with error if error
							res.send {err: err and err.stack, result}
