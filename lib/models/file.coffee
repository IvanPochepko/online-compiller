mongoose = require 'mongoose'

ObjectId = mongoose.Schema.Types.ObjectId
Schema = mongoose.Schema

file = new Schema
	name: String
	path: String
	is_dir: Boolean
	created_at: Date

Model = mongoose.model 'File', file
module.exports = Model
