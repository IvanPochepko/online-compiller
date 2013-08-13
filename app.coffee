
###
 * Module dependencies.
###
express = require 'express'
http = require 'http'
path = require 'path'
mongoose = require 'mongoose'
config = require './conf/config'
require 'express-namespace'
assets = require 'connect-assets'
model = require './lib/db'
app = express();



app.configure () ->
	app.set "port", process.env.PORT or 3000
	app.set "views", __dirname + "/views"
	app.set 'view engine', 'jade'
	app.use express.favicon()
	app.use express.logger 'dev'
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use express.static path.join __dirname, 'public'
	app.use assets {src: path.join __dirname, 'public'}

app.configure 'development', () ->
	app.use express.errorHandler()

model.connectDB(config.db)

app.namespace '/api', require('./controllers/api').boot.bind @, app
app.get '/', (req, res) ->
	res.render 'index', {title: 'Onlile JS Compiller'}

http.createServer(app).listen app.get('port'), () ->
	console.log "Express server listening on port " + app.get('port')

