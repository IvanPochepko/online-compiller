path = require 'path'
async = require 'async'
fs = require 'fs'
exec = require('child_process').exec
client = require('share').client


getLevel = (file) ->
	file.path.substr(1).split('/').length

exports.buildProject = (project, cb) ->
	console.log 'Building project: ' + project.name
	# create all folders
	folders = project.files.filter (file) -> file.is_dir
	folders.push {path: '', name: ''}
	folders.sort (f1, f2) ->
		a = getLevel f1
		b = getLevel f2
		return a < b and -1 or a > b and 1 or f1.name < f2.name and -1 or f1.name > f2.name and 1 or 0
	tasks = []
	rootdir = path.resolve __dirname + '/../projects/' + project._id
	clearRoot = (callback) ->
		command = 'rm -rf ' + rootdir
		exec command, (err, stdout) ->
			callback err, stdout
	# create fs directory for each folders
	folder_tasks = folders.map (f) ->
		return (callback) ->
			console.log 'creating dir: ' + f.path + f.name
			fs.mkdir rootdir + f.path + f.name, (err) ->
				callback and callback err
	# but delete root dir first
	folder_tasks.unshift clearRoot

	# create file for each file
	files = project.files.filter (f) -> not f.is_dir
	file_tasks = files.map (f) ->
		return (callback) ->
			console.log 'creating file: ' + f.path + f.name
			client.open f._id.toString(), 'text', 'http://127.0.0.1:3000/channel', (err, doc) ->
				return callback and callback err if err
				fs.writeFile rootdir + f.path + f.name, doc.snapshot, (err) ->
					doc.close()
					callback and callback err
	tasks = folder_tasks.concat file_tasks

	async.series tasks, (err, results) ->
		console.log 'project built'
		console.log err, results
		cb and cb()
exports.getFile = (project, file, cb) ->
	filepath = path.resolve __dirname + '/../projects/' + project._id + file.path + file.name
	console.log 'reading file: ' + filepath
	fs.readFile filepath, (err, data) ->
		cb and cb err, data
