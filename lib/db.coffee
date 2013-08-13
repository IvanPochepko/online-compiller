mongoose = require 'mongoose'

exports.connectDB = (path) ->
	db = mongoose.connect path
# 'mongodb://localhost/compiller'

