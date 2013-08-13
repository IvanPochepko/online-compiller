production = process.env.NODE_ENV is "production"

if production
	#production configuration
else
	# local configuration
	exports.db = 'mongodb://localhost/compiller'
	exports.domain = 'localhost'

