db = require './db'
LocalStrategy = require("passport-local").Strategy
{User} = db.models

exports.init = (app, passport) ->
	passport.serializeUser (user, done) ->
		done null, user
	passport.deserializeUser (user, done) ->
		done null, user

	# Local Strategy
	localStrategy = new LocalStrategy (email, password, done) ->
		User.findUser {email, password}, (err, user) ->
			return done null, false unless user
			done null, user

	localStrategy._usernameField = 'email'

	passport.use localStrategy
exports.user = (req, res, next) ->
	return res.redirect '/login' unless req.user
	res.locals.user = req.user
	next && next()
