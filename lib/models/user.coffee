mongoose = require 'mongoose'
crypto = require 'crypto'
_ = require 'underscore'

ObjectId = mongoose.Schema.Types.ObjectId
Schema = mongoose.Schema

user = new Schema(
	firstName: String
	lastName: String
	email: String
	password: String
	registered_on: Date
	projects: [{type: ObjectId, ref: 'Project'}]
	shared_projects: [{type: ObjectId, ref: 'Project'}]
)
Model = mongoose.model 'User', user

Model.register = (user, cb) ->
	# md5 create
	user.registered_on = new Date()
	md5 = crypto.createHash 'md5'
	md5.update user.password
	user.password = md5.digest('base64')
	@create user, (err, user) ->
		console.log 'create', arguments
		cb && cb(err, user)




Model.findUser = (user, cb) ->
	console.log 'findUser', user
	md5 = crypto.createHash 'md5'
	md5.update user.password
	user.password = md5.digest('base64')
	# hash password
	@findOne user, (err, user) ->
		console.log 'findOne', err, user
		cb && cb(err, user)


module.exports = Model

