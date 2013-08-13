$(document).ready () ->
	$('.run-js').click () ->
		text = $('.row.text-bar textarea').val()
		data = {text}
		$.ajax
			method: 'POST',
			url: '/api/runjs',
			data: data,
			success: (data) ->
				console.log data
				out = ''
				data.result.forEach (obj) ->
					args = []
					el = for key, el of obj
						el = JSON.stringify el if typeof el is 'object'
						args.push el
					out = out + args.join(', ') + '\n'
				$('.row.result-bar textarea').val(out)
			error: () ->
				console.error arguments

