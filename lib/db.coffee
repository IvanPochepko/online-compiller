mongoose = require 'mongoose'
User = require './models/user'
Project = require './models/project'
#team = require './models/team'
#file = require './models/file'

module.exports =
#	models: {user, project, team, file}
	models: {User, Project}
	connection:
		connect: (path) ->
			db = mongoose.connect path
		disconnect: () ->
		Types: mongoose.Types

