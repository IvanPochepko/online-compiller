production = process.env.NODE_ENV is "production"
development = process.env.NODE_ENV is "development"

	# production configuration
# else if development
	# development configuration
if production
	exports.db = 'mongodb://localhost/compiller'
	exports.domain = 'localhost'
	exports.port = port = process.env.PORT or 3000
	exports.base = 'http://localhost:' + port
else
	# local configuration
	exports.db = 'mongodb://localhost/compiller'
	exports.domain = 'localhost'
	exports.port = port = process.env.PORT or 3000
	exports.base = 'http://localhost:' + port
