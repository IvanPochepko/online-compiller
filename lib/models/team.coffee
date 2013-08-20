mongoose = require 'mongoose'

ObjectId = mongoose.Schema.Types.ObjectId
Schema = mongoose.Schema

team = new Schema(
	id: Number
)


Model = mongoose.model 'Team', Team
module.exports = Model

