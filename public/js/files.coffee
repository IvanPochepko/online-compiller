RUN_EXTENSIONS = ['js', 'coffee']
$(document).ready () ->
	project_id = $('#project-id').val()
	project_name = $('#project-name').val()
	editor = null
	console.log project_name
	opened_doc = null
	loadFiles = (cb) ->
		$.get ['/projects', project_id, 'files.json'].join('/'), (data) ->
			console.log data.files
			initTreeView data.files
			cb and cb()
	createFile = (data, cb) ->
		parent_id = data.parent.id
		path = data.parent.path.length and (data.parent.path + data.parent.name + '/') or '/'
		data =
			project: project_id
			is_dir: data.is_dir
			path: path
			name: data.name
		$.post '/files/new', data, (data) ->
			return unless data.success
			$('#file-modal').modal 'hide'
			appendFile data.file, parent_id
			cb and cb()
	deleteFile = (data, cb) ->
		console.log data
		to_send =
			file: data._id
			project: project_id
		$.post '/files/remove', to_send, (res) ->
			console.log 'removed: ', res
			return unless res.success
			removeNode data.id
			cb and cb()
	renameFile = (data, cb) ->
		node_id = data.file.id
		to_send =
			file: data.file._id
			project: project_id
			name: data.name
		console.log 'rename File', data, to_send
		$.post '/files/rename', to_send, (data) ->
			console.log 'renamed', data
			return unless data.success
			$('#file-modal').modal 'hide'
			updateNode node_id, data.file
			cb and cb()
	openFile = (data, cb) ->
		updateBreadcrumb data.path + data.name
		updateOperations data.name
		console.log 'open file', data, opened_doc
		if opened_doc
			opened_doc.close () ->
				open_doc data._id, cb
		else
			open_doc data._id, cb
	open_doc = (name, cb) ->
		sharejs.open name, 'text', (error, doc) ->
			console.log error, doc.getText()
			opened_doc = doc
			doc.attach_ace editor
			editor.focus()
			cb and cb()
	updateBreadcrumb = (path) ->
		breadcrump = $('.file-path')
		breadcrump.children(':not(:first-of-type)').remove()
		items = path.substr(1).split '/'
		breadcrump.append $('<li><a href="#">' + item + '</a></li>') for item in items
	updateOperations = (file) ->
		console.log file
		regexp = /\.\w+$/
		match = file.match regexp
		console.log match
		ext = match[0].substr 1 if match?.length
		can_log = can_run = ext in RUN_EXTENSIONS
		can_close = !!file
		operations = {close: can_close, run: can_run, logs: can_log}
		console.log 'Operations: ', operations
		$ops = $('.file-operations')
		for op, enabled of operations
			console.log op if enabled
			method = enabled and 'removeClass' or 'addClass'
			$ops.find('.file-' + op)[method] 'disabled'

	loadFiles()
	el = $('#editor')
	console.log el
	window.editor = editor = ace.edit el[0]

	$('#confirm-yes').on 'click', () ->
		data = JSON.parse $('#confirm-modal #confirm-data').val()
		$('#confirm-modal').modal 'hide'
		switch data.action
			when 'delete' then deleteFile data.file
	$('#file-modal form').on 'submit', (e) ->
		e.preventDefault()
		name = $(@).serialize().split('=')[1]
		data = JSON.parse $('#file-modal #file-data').val()
		data.name = name
		switch data.action
			when 'rename' then renameFile data
			when 'create' then createFile data



	### Files tree pluygin configuration ###
	$tree = $('#tree-view')
	initTreeView = (data) ->
		tree = [
			name: project_name
			path: ''
			children: array2tree data
			id: 1
			is_dir: true
			is_root: true
			is_open: true
		]
		$tree.tree
			data: tree
			useContextMenu: false
			onCreateLi: (node, $li) ->
				# Add 'icon' span before title
				type = node.is_dir && 'folder' or 'file'
				$li.find('.jqtree-title').before('<img src="/img/' + type + '.png" height="20px">&nbsp;');
				$li.attr 'tree_id', node.id
				cssClass = node.is_root && 'root' or type
				$li.addClass 'my-jqtree-' + cssClass
		$tree.bind 'tree.click', (event) ->
			console.log event.node
		$tree.bind 'tree.contextmenu', (event) ->
			console.log event
			console.log event.click_event.isDefaultPrevented()
	appendFile = (file, parent_id) ->
		console.log file, tree_id
		file.id = tree_id++
		parent_node = $tree.tree 'getNodeById', parent_id
		node = _.find parent_node.children, (child) -> child.is_dir is file.is_dir and child.name > file.name
		if !node and file.is_dir and parent_node.children?.length
			node = parent_node.children[0]
		if node
			$tree.tree 'addNodeBefore', file, node
		else
			$tree.tree 'appendNode', file, parent_node

	updateNode = (node_id, file) ->
		node = $tree.tree 'getNodeById', node_id
		return unless node
		$tree.tree 'updateNode', node, {name: file.name}
		level = node.parent.children
		console.log 'level got', level
		return if level.length is 1
		next_node = _.find level, (el) ->
			console.log el.name, el.id != node.id, el.is_dir is node.is_dir, el.name > file.name
			el.id != node.id and el.is_dir is node.is_dir and el.name > file.name
		console.log 'next node found', next_node
		return unless next_node
		$tree.tree 'moveNode', node, next_node, 'before'
	removeNode = (id) ->
		node = $tree.tree 'getNodeById', id
		console.log 'removeNode', id, node
		return unless node
		$tree.tree 'removeNode', node
	### Define context menu for Tree View ###
	getNodeByContext = (ctx) ->
		el = context.getContextData ctx.id
		tree_id = $(el).attr 'tree_id'
		node = $tree.tree 'getNodeById', tree_id

	common_context = [{
		text: 'Rename'
		action: (e) ->
			node = getNodeByContext @
			$file = $('#file-modal')
			file = _.pick node, 'path', 'name', '_id', 'id'
			type = node.is_dir and 'folder ' or 'file '
			$file.find('.modal-title').text 'Rename ' + type + node.name
			$file.find('#file-data').val JSON.stringify {file, is_dir: false, action: 'rename'}
			$file.find('#modal-filename').val node.name
			$file.modal()
		order: 30
	}, {
		text: 'Delete'
		action: (e) ->
			node = getNodeByContext @
			if node.is_dir and node.children?.length
				confirm_warning = 'Warning! Folder is not empty.'
				$('#confirm-modal .modal-warning').show().text confirm_warning
			else
				$('#confirm-modal .modal-warning').hide().text ''
			$('#confirm-modal .modal-title').text 'Delete ' + node.name
			file = _.pick node, '_id', 'id'
			$('#confirm-modal #confirm-data').val JSON.stringify {file, action: 'delete'}
			$('#confirm-modal').modal()

			console.log 'Delete ', node
		order: 40
	}]

	root_context = [
		text: 'Expand / Collapse'
		action: (e) ->
			node = getNodeByContext @
			method = node.is_open and 'closeNode' or 'openNode'
			$tree.tree method, node
		order: 10,
			divider: true,
			order: 45
		text: 'New File'
		action: () ->
			node = getNodeByContext @
			$file = $('#file-modal')
			parent = _.pick node, 'path', 'name', 'id'
			$file.find('.modal-title').text 'Create new file'
			$file.find('#file-data').val JSON.stringify {parent, is_dir: false, action: 'create'}
			$file.find('#modal-filename').val ''
			$file.modal()
		order: 50,
			text: 'New Folder'
			action: () ->
				node = getNodeByContext @
				$file = $('#file-modal')
				parent = _.pick node, 'path', 'name', 'id'
				$file.find('.modal-title').text 'Create new folder'
				$file.find('#file-data').val JSON.stringify {parent, is_dir: true, action: 'create'}
				$file.find('#modal-filename').val ''
				$file.modal()
			order: 60
	]

	folder_context = common_context.concat root_context

	file_context = common_context.concat [{
		text: 'Open'
		action: (e) ->
			node = getNodeByContext @
			openFile node
		order: 20
	}]

	file_context = _.sortBy file_context, 'order'
	folder_context = _.sortBy folder_context, 'order'
	root_context = _.sortBy root_context, 'order'

	context.init()
	context.attach '.my-jqtree-file', file_context
	context.attach '.my-jqtree-folder', folder_context
	context.attach '.my-jqtree-root', root_context

tree_id = 2
array2tree = (arr) ->
	path = '/'
	tree = []
	arr.forEach (el) -> el.id = tree_id++
	tree =  fill_level arr, path
fill_level = (arr, path) ->
	level = []
	other = []

	arr.forEach (el) ->
		if el.path is path
			level.push el
		else
			other.push el
	level.sort sortFiles
	for el in level
		continue unless el.is_dir
		level_path = path + el.name + '/'
		el.children = fill_level other, level_path
	level
sortFiles = (f1, f2) ->
	return f1.name > f2.name and 1 or f1.name is f2.name and 0 or -1 if f1.is_dir is f2.is_dir
	return f1.is_dir and -1 or 1
