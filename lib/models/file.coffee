mongoose = require 'mongoose'

ObjectId = mongoose.Schema.Types.ObjectId
Schema = mongoose.Schema

file = new Schema(
	id: Number
)

Model = mongoose.model 'File', file
module.exports = Model

