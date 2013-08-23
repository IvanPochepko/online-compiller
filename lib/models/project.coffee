mongoose = require 'mongoose'

ObjectId = mongoose.Schema.Types.ObjectId
Schema = mongoose.Schema

project = new Schema
	id: Number
	name: String
	description: String
	owner: {type: ObjectId, ref: 'User'}
	collaborators: [{type: ObjectId, ref: 'User'}]
	files: [{type: ObjectId, ref: 'File'}]

Model = mongoose.model 'Project', project
module.exports = Model
