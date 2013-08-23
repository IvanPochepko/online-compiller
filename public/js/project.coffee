$(document).ready () ->
	id= $('#project-id').val()
	$('.delete').click () ->
		$('#confirm-modal').modal()
	$('.edit').click () ->
		$('#project-modal').modal()
	$('.add-collaborator').click () ->
		$('#collaborator-modal').modal()
	$('#confirm-yes').click () ->
		url='/projects/'+id+'/delete'
		console.log 'url', url
		$.ajax(
			url:url
			method: 'POST'
			success: (data) ->
				console.log 'success', data
				window.location = '/user/projects'
		)
	$('#add-collaborator-agreee').click () ->
		$('.alert-danger').addClass 'hide'
		email = $('#input-collaborator-email').val()
		if email.length is 0
			$('.email-alert').removeClass 'hide'
			return
		data = {email}
		url='/projects/'+id+'/add_collaborator'
		$.ajax(
			url:url
			method: 'POST'
			data: data
			success: (data) ->
				unless data.collaborator
					$('.not-found-alert').removeClass 'hide'
					return
				else
					window.location = '/projects/'+id
		)
