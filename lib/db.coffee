mongoose = require 'mongoose'
User = require './models/user'
Project = require './models/project'
File = require './models/file'
#team = require './models/team'

module.exports =
#	models: {user, project, team, file}
	models: {User, Project, File}
	connection:
		connect: (path) ->
			db = mongoose.connect path
		disconnect: () ->
		Types: mongoose.Types
