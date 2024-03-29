@tool
extends Control


const new_project_dialog := preload("../new_project_dialog.tscn")
const edit_canvas_size := preload("../edit_canvas_size.tscn")
const startup_window := preload("../startup_window.tscn")
const animation_preview_window := preload("../animation_sheet_preview.tscn")
const image_reference_window := preload("../window_reference.tscn")
const import_window := preload("../import_window.tscn")
const shorcut : EditorShorcut = preload("../../resources/editor_shorcut.tres")

const Tool := preload("../editor_canvas/tool.gd")
const MoveTool := preload("../editor_canvas/move_tool.gd")

enum PixelPenID{
	ABOUT = 0,
	PREFERENCE,
	QUIT
}

enum FileID{
	NEW = 0,
	OPEN,
	OPEN_RECENTS,
	SAVE,
	SAVE_AS,
	IMPORT,
	EXPORT,
	QUICK_EXPORT,
	CLOSE
}

enum ExportAsID{
	JPG = 0,
	PNG,
	WEBP
}

enum EditID{
	UNDO = 0,
	REDO,
	DELETE_ON_SELECTION,
	COPY,
	CUT,
	PASTE,
	CREATE_BRUSH,
	CANVAS_SIZE
}

enum PaletteID{
	RESET = 0,
	SORT_COLOR,
	DELETE_UNUSED,
	DELETE_SELECTED_COLOR,
	LOAD_AND_REPLACE,
	LOAD_AND_MERGE,
	SAVE
}

enum ViewID{
	SHOW_GRID = 0,
	SHOW_VERTICAL_MIRROR_GUIDE,
	SHOW_HORIZONTAL_MIRROR_GUIDE,
	CLEAR_SELECTION,
	ROTATE_CANVAS_90,
	ROTATE_CANVAS_MIN_90,
	FLIP_CANVAS_HORIZONTAL,
	FLIP_CANVAS_VERTICAL,
	RESET_CANVAS_TRANSFORM,
	SHOW_ANIMATION_PREVIEW,
	NEW_IMAGE_REFERENCE,
	TOGGLE_TINT_SELECTED_LAYER,
	EDIT_SELECTION_ONLY,
	SHOW_TILE,
	SHOW_PREVIEW,
	FILTER_GRAYSCALE,
	SHOW_INFO
}

@export var pixel_pen_menu : MenuButton
@export var file_menu: MenuButton
@export var edit_menu : MenuButton
@export var palette_menu : MenuButton
@export var view_menu : MenuButton
@export var canvas : Node2D
@export var canvas_color : ColorRect
@export var canvas_color_base : Color
@export var canvas_color_sample : Color
@export var debug_label : Label
@export var preview_node : Control
var recent_submenu : PopupMenu
var _new_project_dialog : ConfirmationDialog


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	if not Engine.is_editor_hint():
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	_init_popup_menu()
	_set_shorcut()
	connect_signal()
	_on_project_file_changed()


func _on_project_file_changed():
	_on_selection_texture_changed()
	
	var pixelpen_popup = pixel_pen_menu.get_popup()
	pixelpen_popup.set_item_disabled(pixelpen_popup.get_item_index(PixelPenID.ABOUT), true)
	pixelpen_popup.set_item_disabled(pixelpen_popup.get_item_index(PixelPenID.PREFERENCE), true)
	
	var disable : bool = PixelPen.current_project == null
	var quick_export_path_empty : bool = false
	if PixelPen.current_project != null:
		quick_export_path_empty = PixelPen.current_project.last_export_file_path == ""
		
		view_menu.get_popup().set_item_checked(view_menu.get_popup().get_item_index(ViewID.EDIT_SELECTION_ONLY), PixelPen.current_project.use_sample)
		canvas_color.color = canvas_color_sample if PixelPen.current_project.use_sample else canvas_color_base
		
		edit_menu.get_popup().set_item_disabled(edit_menu.get_popup().get_item_index(EditID.CANVAS_SIZE), PixelPen.current_project.use_sample)
	else:
		canvas_color.color = canvas_color_base
	
	var file_popup = file_menu.get_popup()
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.SAVE), disable)
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.SAVE_AS), disable)
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.EXPORT), disable )
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.QUICK_EXPORT), disable or quick_export_path_empty)
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.CLOSE), disable )
	edit_menu.disabled = disable
	palette_menu.disabled = disable
	view_menu.disabled = disable
	
	var is_window_running : bool = false
	if get_window() and get_window().is_inside_tree() and get_window().has_method("is_window_running"):
		is_window_running = get_window().is_window_running()
	
	if disable and (not Engine.is_editor_hint() or is_window_running):
		var ok = PixelPen.load_cache_project()
		if not ok:
			_on_request_startup_window()
	
	if PixelPen.current_project != null and not PixelPen.current_project.property_changed.is_connected(_on_property_changed):
		(PixelPen.current_project as PixelPenProject).property_changed.connect(_on_property_changed)
	
	if PixelPen.current_project != null:
		PixelPen.current_project.undo_redo = UndoRedoManager.new()
		
	_update_title()
	_update_recent_submenu()


func _on_request_startup_window():
	var startup = startup_window.instantiate()
	add_child(startup)
	startup.popup_centered()


func _update_title():
	if is_inside_tree():
		if PixelPen.current_project == null:
			get_window().title = "Empty - " + PixelPen.EDITOR_TITTLE
			return
		
		var is_saved : bool = (PixelPen.current_project as PixelPenProject).is_saved
		
		var canvas_size = str("(", PixelPen.current_project.canvas_size.x, "x", PixelPen.current_project.canvas_size.y , "px)")
		if PixelPen.current_project.use_sample:
			canvas_size = str("(region ", 
					PixelPen.current_project.canvas_size.x, "x", PixelPen.current_project.canvas_size.y , "px of ", 
					PixelPen.current_project._cache_canvs_size.x, "x", PixelPen.current_project._cache_canvs_size.y , "px)")
		get_window().title = PixelPen.current_project.project_name + " " + canvas_size + " - " + PixelPen.EDITOR_TITTLE
		if PixelPen.current_project.file_path == "" or not is_saved:
			get_window().title = "(*)" + get_window().title


func _update_recent_submenu():
	recent_submenu.clear(true)
	if PixelPen.recent_projects != null and PixelPen.recent_projects.size() > 0:
		for i in range(PixelPen.recent_projects.size()):
			recent_submenu.add_item(PixelPen.recent_projects[i], i)
	else:
		recent_submenu.add_item("_", 0)


func _init_popup_menu():
	var pixelpen_popup : PopupMenu = pixel_pen_menu.get_popup()
	pixelpen_popup.add_item("About", PixelPenID.ABOUT)
	pixelpen_popup.add_item("Preferences", PixelPenID.PREFERENCE)
	pixelpen_popup.add_separator("", 100)
	pixelpen_popup.add_item("Quit PixePen", PixelPenID.QUIT)
	
	var file_popup : PopupMenu = file_menu.get_popup()
	file_popup.add_item("New Project...", FileID.NEW)
	file_popup.add_item("Open Existing Project...", FileID.OPEN)
	file_popup.add_item("Open Recents Project...", FileID.OPEN_RECENTS)
	file_popup.add_separator("", 100)
	file_popup.add_item("Save Project", FileID.SAVE)
	file_popup.add_item("Save Project As...", FileID.SAVE_AS)
	file_popup.add_separator("", 100)
	file_popup.add_item("Import Image...", FileID.IMPORT)
	file_popup.add_item("Exports As Image...", FileID.EXPORT)
	file_popup.add_item("Quick Export", FileID.QUICK_EXPORT)
	file_popup.add_separator("", 100)
	file_popup.add_item("Close Project", FileID.CLOSE)
	
	recent_submenu = PopupMenu.new()
	recent_submenu.set_name("recent_submenu")
	_update_recent_submenu()
	recent_submenu.id_pressed.connect(func (id : int):
			if PixelPen.recent_projects != null and PixelPen.recent_projects.size() > id:
				PixelPen.load_project(PixelPen.recent_projects[id])
			)
	file_popup.add_child(recent_submenu)
	file_popup.set_item_submenu(file_popup.get_item_index(FileID.OPEN_RECENTS), "recent_submenu")
	
	var import_submenu : PopupMenu = PopupMenu.new()
	import_submenu.set_name("import_submenu")
	import_submenu.add_item("*.jpg", ExportAsID.JPG)
	import_submenu.add_item("*.png", ExportAsID.PNG)
	import_submenu.add_item("*.webp", ExportAsID.WEBP)
	import_submenu.id_pressed.connect(_on_export)
	file_popup.add_child(import_submenu)
	file_popup.set_item_submenu(file_popup.get_item_index(FileID.EXPORT), "import_submenu")
	
	var edit_popup : PopupMenu = edit_menu.get_popup()
	edit_popup.add_item("Undo", EditID.UNDO)
	edit_popup.add_item("Redo", EditID.REDO)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Delete on selection", EditID.DELETE_ON_SELECTION)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Copy", EditID.COPY)
	edit_popup.add_item("Cut", EditID.CUT)
	edit_popup.add_item("Paste", EditID.PASTE)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Create brush pattern", EditID.CREATE_BRUSH)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Canvas size...", EditID.CANVAS_SIZE)
	
	var palette_popup : PopupMenu = palette_menu.get_popup()
	palette_popup.add_item("Reset To Default Preset", PaletteID.RESET)
	palette_popup.add_item("Sort Color", PaletteID.SORT_COLOR)
	palette_popup.add_item("Delete Unused Color", PaletteID.DELETE_UNUSED)
	palette_popup.add_item("Delete Selected Color", PaletteID.DELETE_SELECTED_COLOR)
	palette_popup.add_separator("", 100)
	palette_popup.add_item("Load and replace...", PaletteID.LOAD_AND_REPLACE)
	palette_popup.add_item("Load and merge..", PaletteID.LOAD_AND_MERGE)
	palette_popup.add_item("Save As...", PaletteID.SAVE)
	
	var view_popup : PopupMenu = view_menu.get_popup()
	view_popup.add_check_item("Show grid", ViewID.SHOW_GRID)
	view_popup.add_check_item("Show vertical mirror guid", ViewID.SHOW_VERTICAL_MIRROR_GUIDE)
	view_popup.add_check_item("how horizontal mirror guid", ViewID.SHOW_HORIZONTAL_MIRROR_GUIDE)
	view_popup.add_separator("", 100)
	view_popup.add_item("Clear selection", ViewID.CLEAR_SELECTION)
	view_popup.add_separator("", 100)
	view_popup.add_item("Rotate canvas 90", ViewID.ROTATE_CANVAS_90)
	view_popup.add_item("Rotate canvas -90", ViewID.ROTATE_CANVAS_MIN_90)
	view_popup.add_item("Flip canvas horizontal", ViewID.FLIP_CANVAS_HORIZONTAL)
	view_popup.add_item("Flip canvas vertical", ViewID.FLIP_CANVAS_VERTICAL)
	view_popup.add_item("Reset canvas transform", ViewID.RESET_CANVAS_TRANSFORM)
	view_popup.add_separator("", 100)
	view_popup.add_item("Show animation sheet preview...", ViewID.SHOW_ANIMATION_PREVIEW)
	view_popup.add_item("New image references...", ViewID.NEW_IMAGE_REFERENCE)
	view_popup.add_separator("", 100)
	view_popup.add_check_item("Edit selection only", ViewID.EDIT_SELECTION_ONLY)
	view_popup.add_check_item("Show tile", ViewID.SHOW_TILE)
	view_popup.add_check_item("Show preview", ViewID.SHOW_PREVIEW)
	view_popup.add_check_item("Tint black to layer", ViewID.TOGGLE_TINT_SELECTED_LAYER)
	view_popup.add_check_item("Filter grayscale", ViewID.FILTER_GRAYSCALE)
	view_popup.add_check_item("Show info", ViewID.SHOW_INFO)
	
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_GRID), canvas.show_grid)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_VERTICAL_MIRROR_GUIDE), canvas.show_symetric_vertical)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_HORIZONTAL_MIRROR_GUIDE), canvas.show_symetric_horizontal)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_TILE), canvas.show_tile)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_PREVIEW), preview_node.visible)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.TOGGLE_TINT_SELECTED_LAYER), canvas.silhouette)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.FILTER_GRAYSCALE), canvas.show_view_grayscale)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_INFO), debug_label.visible)


func _set_shorcut():
	var pixelpen_popup := pixel_pen_menu.get_popup()
	pixelpen_popup.set_item_shortcut(pixelpen_popup.get_item_index(PixelPenID.QUIT), shorcut.quit_editor)
	
	var file_popup := file_menu.get_popup()
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.NEW), shorcut.new_project)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.OPEN), shorcut.open_project)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.SAVE), shorcut.save)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.SAVE_AS), shorcut.save_as)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.QUICK_EXPORT), shorcut.quick_export)
	
	var edit_popup := edit_menu.get_popup()
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.UNDO), shorcut.undo)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.REDO), shorcut.redo)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.DELETE_ON_SELECTION), shorcut.tool_delete_selected)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.COPY), shorcut.copy)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.CUT), shorcut.cut)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.PASTE), shorcut.paste)
	
	var view_popup := view_menu.get_popup()
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.SHOW_GRID), shorcut.view_show_grid)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.CLEAR_SELECTION), shorcut.tool_remove_selection)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.ROTATE_CANVAS_90), shorcut.rotate_canvas_90)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.ROTATE_CANVAS_MIN_90), shorcut.rotate_canvas_min90)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.FLIP_CANVAS_HORIZONTAL), shorcut.flip_canvas_horizontal)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.FLIP_CANVAS_VERTICAL), shorcut.flip_canvas_vertical)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.RESET_CANVAS_TRANSFORM), shorcut.reset_canvas_transform)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.TOGGLE_TINT_SELECTED_LAYER), shorcut.toggle_tint_layer)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.EDIT_SELECTION_ONLY), shorcut.toggle_edit_selection_only)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.SHOW_TILE), shorcut.view_show_tile)


func connect_signal():
	pixel_pen_menu.get_popup().id_pressed.connect(_on_pixelpen_popup_pressed)
	file_menu.get_popup().id_pressed.connect(_on_file_popup_pressed)
	edit_menu.get_popup().id_pressed.connect(_on_edit_popup_pressed)
	palette_menu.get_popup().id_pressed.connect(_on_palette_popup_pressed)
	view_menu.get_popup().id_pressed.connect(_on_view_popup_pressed)
	
	PixelPen.request_new_project.connect(_new)
	PixelPen.request_open_project.connect(_open)
	PixelPen.request_save_project.connect(_save)
	PixelPen.request_save_as_project.connect(_save_as)
	PixelPen.project_file_changed.connect(_on_project_file_changed)
	canvas.selection_tool_hint.texture_changed.connect(_on_selection_texture_changed)


func _on_property_changed(is_saved : bool):
	if PixelPen.current_project != null:
		PixelPen.current_project.is_saved = is_saved
	_update_title()


func _new():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_new_project_dialog = new_project_dialog.instantiate()
	_new_project_dialog.confirmed.connect(func():
			_new_project_dialog.hide()
			PixelPen.dialog_visibled.emit(false)
			PixelPen.project_file_changed.emit()
			_new_project_dialog.queue_free()
			)
	_new_project_dialog.canceled.connect(func():
			_new_project_dialog.hide()
			PixelPen.dialog_visibled.emit(false)
			_new_project_dialog.queue_free()
			)
	add_child(_new_project_dialog)
	PixelPen.dialog_visibled.emit(true)
	_new_project_dialog.popup_centered()


func _open():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.filters = ["*.res"]
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			PixelPen.load_project(file)
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
		
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(720, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)


func _save():
	if PixelPen.current_project == null:
		return
	if (PixelPen.current_project as PixelPenProject).file_path == "":
		_show_save_as_dialog(
				func (file_path):
					if file_path != "":
						_save_project(file_path)
		)
	else:
		_save_project(PixelPen.current_project.file_path)


func _save_as():
	if PixelPen.current_project == null:
		return
	_show_save_as_dialog(func (file_path):
			if file_path != "":
				_save_project(file_path)
			)


func _save_project(file_path : String):
	var prev_path = PixelPen.current_project.file_path
	var prev_name = PixelPen.current_project.project_name
	PixelPen.current_project.file_path = file_path
	PixelPen.current_project.project_name = file_path.get_file().get_basename()
	var err = ResourceSaver.save(PixelPen.current_project, file_path)
	if err == OK:
		PixelPen.current_project.is_saved = true
		(PixelPen.current_project as PixelPenProject).property_changed.emit(true)
	else:
		PixelPen.current_project.file_path = prev_path
		PixelPen.current_project.project_name = prev_name


func _show_save_as_dialog(callback : Callable = Callable()):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".res")
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.filters = ["*.res"]
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			callback.call(file)
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			callback.call("")
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(720, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)


func _close_project():
	PixelPen.current_project = null
	PixelPen.save_cache_project_config()
	PixelPen.project_file_changed.emit()


func _on_selection_texture_changed():
	var disable = canvas.selection_tool_hint.texture == null
	
	var edit_popup = edit_menu.get_popup()
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.DELETE_ON_SELECTION), disable)
	
	var view_popup = view_menu.get_popup()
	view_popup.set_item_disabled(view_popup.get_item_index(ViewID.CLEAR_SELECTION), disable)


func _on_pixelpen_popup_pressed(id : int):
	if id == PixelPenID.QUIT:
		if Engine.is_editor_hint():
			get_window().hide()
			get_window().queue_free()
		else:
			get_tree().quit()


func _on_file_popup_pressed(id : int):
	if id == FileID.NEW:
		_new()
		
	elif id == FileID.OPEN:
		_open()
	
	elif id == FileID.SAVE:
		_save()
	
	elif id == FileID.SAVE_AS:
		_save_as()
		
	elif id == FileID.IMPORT:
		var callback_no_project = func(file : String):
			if file != "":
				var window : ConfirmationDialog = import_window.instantiate()
				add_child(window)
				window.confirmed.connect(func():
						var image : Image = window.get_image() 
						var current_project = PixelPenProject.new()
						current_project.initialized(
								image.get_size(), "Untitled", 16, "", false
								)
						PixelPen.current_project = current_project
						var layer_uuid : String = PixelPen.current_project.import_image(image, file)
						PixelPen.current_project.project_name = PixelPen.current_project.get_index_image(layer_uuid).label
						window.closed.emit()
						window.queue_free()
						PixelPen.project_file_changed.emit()
						)
				window.canceled.connect(func():
						window.closed.emit()
						window.queue_free()
						)
				window.show_file(file)
				window.popup_centered()
				PixelPen.dialog_visibled.emit(true)
				await window.closed
				PixelPen.dialog_visibled.emit(false)
		var callback = func(files : PackedStringArray):
			if not files.is_empty():
				(PixelPen.current_project as PixelPenProject).create_undo_layer_and_palette("Add layer", func ():
						PixelPen.layer_items_changed.emit()
						(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
						PixelPen.palette_changed.emit()
						)
				for i in range(files.size()):
					var window : ConfirmationDialog = import_window.instantiate()
					add_child(window)
					window.confirmed.connect(func():
							(PixelPen.current_project as PixelPenProject).import_image(window.get_image() , files[i])
							window.closed.emit()
							window.queue_free()
							)
					window.canceled.connect(func():
							window.closed.emit()
							window.queue_free()
							)
					window.show_file(files[i])
					window.popup_centered()
					await window.closed
				(PixelPen.current_project as PixelPenProject).create_redo_layer_and_palette(func ():
						PixelPen.layer_items_changed.emit()
						(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
						PixelPen.palette_changed.emit()
						)
				PixelPen.layer_items_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				PixelPen.palette_changed.emit()
		if PixelPen.current_project == null:
			get_image_file(callback_no_project, FileDialog.FILE_MODE_OPEN_FILE)
		else:
			get_image_file(callback, FileDialog.FILE_MODE_OPEN_FILES)
	
	elif id == FileID.QUICK_EXPORT:
		var file : String = PixelPen.current_project.last_export_file_path
		var ext : String = file.get_extension().to_lower()
		if ext == "jpg" or ext == "jpeg":
			(PixelPen.current_project as PixelPenProject).export_jpg_image(file)
		elif ext == "png":
			(PixelPen.current_project as PixelPenProject).export_png_image(file)
		elif ext == "webp":
			(PixelPen.current_project as PixelPenProject).export_webp_image(file)
		(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
		
		##TODO: remove below on export debug
		if get_window().has_method("scan"):
			get_window().scan()
	
	elif id == FileID.CLOSE:
		_close_project()


func _on_edit_popup_pressed(id : int):
	match id:
		EditID.UNDO:
			PixelPen.current_project.undo()
		EditID.REDO:
			PixelPen.current_project.redo()
		EditID.DELETE_ON_SELECTION:
			PixelPen.tool_changed.emit(
					PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
					PixelPen.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED, false)
		EditID.COPY:
			MoveTool.mode = MoveTool.Mode.COPY
			if canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE:
				canvas.canvas_paint.tool._show_guid = true
			else:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MOVE, true)
		EditID.CUT:
			MoveTool.mode = MoveTool.Mode.CUT
			if canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE:
				canvas.canvas_paint.tool._show_guid = true
			else:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MOVE, true)
		EditID.PASTE:
			if canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE and canvas.canvas_paint.tool.mode != MoveTool.Mode.UNKNOWN:
				canvas.canvas_paint.tool._on_move_commit()
		EditID.CREATE_BRUSH:
			PixelPen.userconfig.make_brush_from_project()
		EditID.CANVAS_SIZE:
			_open_canvas_size_window()


func _on_palette_popup_pressed(id : int):
	if id == PaletteID.RESET:
		(PixelPen.current_project as PixelPenProject).create_undo_palette("Palette", func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
				
		(PixelPen.current_project as PixelPenProject).palette.set_color_index_preset()
		
		(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		PixelPen.palette_changed.emit()
		(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
		
	elif id == PaletteID.SORT_COLOR:
		(PixelPen.current_project as PixelPenProject).create_undo_layer_and_palette("Sort palette", func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		(PixelPen.current_project as PixelPenProject).sort_palette()
		(PixelPen.current_project as PixelPenProject).create_redo_layer_and_palette(func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		PixelPen.palette_changed.emit()
		(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
		
	elif id == PaletteID.DELETE_UNUSED:
		(PixelPen.current_project as PixelPenProject).create_undo_layer_and_palette("Sort palette", func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		(PixelPen.current_project as PixelPenProject).delete_unused_color_palette()
		(PixelPen.current_project as PixelPenProject).create_redo_layer_and_palette(func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		PixelPen.palette_changed.emit()
		(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
	elif id == PaletteID.DELETE_SELECTED_COLOR:
		(PixelPen.current_project as PixelPenProject).create_undo_layer_and_palette("Sort palette", func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		(PixelPen.current_project as PixelPenProject).delete_color(Tool._index_color)
		(PixelPen.current_project as PixelPenProject).create_redo_layer_and_palette(func():
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		PixelPen.palette_changed.emit()
		(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
	
	elif id == PaletteID.LOAD_AND_REPLACE:
		var callback = func(file):
			if file != "":
				(PixelPen.current_project as PixelPenProject).create_undo_palette("Load palette", func():
						PixelPen.palette_changed.emit()
						(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
						)
				
				(PixelPen.current_project as PixelPenProject).palette.load_image(file)
				
				(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
						PixelPen.palette_changed.emit()
						(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
						)
				
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
		get_image_file(callback, FileDialog.FILE_MODE_OPEN_FILE)
		
	elif id == PaletteID.LOAD_AND_MERGE:
		var callback = func(file):
			if file != "":
				(PixelPen.current_project as PixelPenProject).create_undo_palette("Load palette", func():
						PixelPen.palette_changed.emit()
						(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
						)
				
				(PixelPen.current_project as PixelPenProject).palette.load_image(file, true)
				
				(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
						PixelPen.palette_changed.emit()
						(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
						)
				
				PixelPen.palette_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
		get_image_file(callback, FileDialog.FILE_MODE_OPEN_FILE)
		
	elif id == PaletteID.SAVE:
		var callback = func(file):
			if file != "":
				(PixelPen.current_project as PixelPenProject).palette.save_image(file)
		get_image_file(callback, FileDialog.FILE_MODE_SAVE_FILE)


func _on_view_popup_pressed(id : int):
	var popup : PopupMenu = view_menu.get_popup()
	var index = popup.get_item_index(id)
	if id == ViewID.SHOW_GRID:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		canvas.show_grid = popup.is_item_checked(index)
	elif id == ViewID.SHOW_VERTICAL_MIRROR_GUIDE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		canvas.show_symetric_vertical = popup.is_item_checked(index)
	elif id == ViewID.SHOW_HORIZONTAL_MIRROR_GUIDE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		canvas.show_symetric_horizontal = popup.is_item_checked(index)
	elif id == ViewID.CLEAR_SELECTION:
		PixelPen.tool_changed.emit(
				PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
				PixelPen.ToolBoxSelection.TOOL_SELECTION_REMOVE, false)
	elif id == ViewID.ROTATE_CANVAS_90:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.rotate(PI * 0.5)
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	elif id == ViewID.ROTATE_CANVAS_MIN_90:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.rotate(PI * -0.5)
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	elif id == ViewID.FLIP_CANVAS_HORIZONTAL:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.scale.x *= -1
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	elif id == ViewID.FLIP_CANVAS_VERTICAL:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.scale.y *= -1
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	elif id == ViewID.RESET_CANVAS_TRANSFORM:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.scale = Vector2.ONE
		canvas.rotation = 0
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	elif id == ViewID.SHOW_ANIMATION_PREVIEW:
		var window = animation_preview_window.instantiate()
		add_child(window)
		window.popup_in_last_position()
		window.init()
	elif id == ViewID.NEW_IMAGE_REFERENCE:
		get_image_file(func(files : PackedStringArray):
				for file in files:
					var window = image_reference_window.instantiate()
					window.load_texture(file)
					add_child(window)
					window.popup_centered()
					window.grab_focus()
				,FileDialog.FILE_MODE_OPEN_FILES
				)
	elif id == ViewID.EDIT_SELECTION_ONLY:
		if (PixelPen.current_project as PixelPenProject).use_sample:
			(PixelPen.current_project as PixelPenProject).set_mode(0)
		elif canvas.selection_tool_hint.texture != null:
			var mask : Image = MaskSelection.get_image_no_margin(canvas.selection_tool_hint.texture.get_image())
			(PixelPen.current_project as PixelPenProject).set_mode(1, mask)
		popup.set_item_checked(index, (PixelPen.current_project as PixelPenProject).use_sample)
		PixelPen.project_file_changed.emit()
	elif id == ViewID.SHOW_TILE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		canvas.show_tile = popup.is_item_checked(index)
		PixelPen.thumbnail_changed.emit()
	elif id == ViewID.SHOW_PREVIEW:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		preview_node.visible = popup.is_item_checked(index)
	elif id == ViewID.TOGGLE_TINT_SELECTED_LAYER:
		var active_layer_uuid : String = (PixelPen.current_project as PixelPenProject).active_layer_uuid
		canvas.silhouette = false
		for layer in (PixelPen.current_project as PixelPenProject).index_image:
			layer.silhouette = not layer.silhouette and layer.layer_uuid == active_layer_uuid
			canvas.silhouette = canvas.silhouette or layer.silhouette
		PixelPen.layer_items_changed.emit()
		popup.set_item_checked(index, canvas.silhouette)
	elif id == ViewID.FILTER_GRAYSCALE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		canvas.show_view_grayscale = popup.is_item_checked(index)
	elif id == ViewID.SHOW_INFO:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		debug_label.visible = popup.is_item_checked(index)


func get_image_file(callback : Callable, mode : FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE):
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = mode
	_file_dialog.filters = ["*.png, *.jpg, *.jpeg ; Supported Images"]
		
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			callback.call(file)
			_file_dialog.queue_free()
			)
	_file_dialog.files_selected.connect(func(files):
			_file_dialog.hide()
			callback.call(files)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			if mode == FileDialog.FileMode.FILE_MODE_OPEN_FILES:
				callback.call([])
			else:
				callback.call("")
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered()
	_file_dialog.grab_focus()


func _open_canvas_size_window():
	var edit_canvas_window = edit_canvas_size.instantiate()
	edit_canvas_window.canvas_width = PixelPen.current_project.canvas_size.x 
	edit_canvas_window.canvas_height = PixelPen.current_project.canvas_size.y
	edit_canvas_window.checker_size = PixelPen.current_project.checker_size
	edit_canvas_window.custom_action.connect(func(action):
			if action == "on_reset":
				edit_canvas_window.canvas_width = PixelPen.current_project.canvas_size.x 
				edit_canvas_window.canvas_height = PixelPen.current_project.canvas_size.y
				edit_canvas_window.checker_size = PixelPen.current_project.checker_size
			)
	edit_canvas_window.confirmed.connect(func():
			if edit_canvas_window.checker_size != PixelPen.current_project.checker_size:
				PixelPen.current_project.checker_size = edit_canvas_window.checker_size
				canvas.update_background_shader_state()
			var changed : bool = edit_canvas_window.canvas_width != PixelPen.current_project.canvas_size.x 
			changed = changed or edit_canvas_window.canvas_height != PixelPen.current_project.canvas_size.y
			if changed:
				(PixelPen.current_project as PixelPenProject).resize_canvas(
					Vector2i(edit_canvas_window.canvas_width, edit_canvas_window.canvas_height),
					edit_canvas_window.anchor
				)
				PixelPen.project_file_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			edit_canvas_window.queue_free()
			)
	edit_canvas_window.canceled.connect(func():
			edit_canvas_window.queue_free()
			)
	add_child(edit_canvas_window)
	edit_canvas_window.popup_centered()


func _on_export(id : int):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	
	if id == ExportAsID.JPG:
		_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".jpg")
	elif id == ExportAsID.PNG:
		_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".png")
	elif id == ExportAsID.WEBP:
		_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".webp")
	
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	
	if id == ExportAsID.JPG:
		_file_dialog.filters = ["*.jpg"]
	elif id == ExportAsID.PNG:
		_file_dialog.filters = ["*.png"]
	elif id == ExportAsID.WEBP:
		_file_dialog.filters = ["*.webp"]
		
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			if id == ExportAsID.JPG:
				(PixelPen.current_project as PixelPenProject).export_jpg_image(file)
			elif id == ExportAsID.PNG:
				(PixelPen.current_project as PixelPenProject).export_png_image(file)
			elif id == ExportAsID.WEBP:
				(PixelPen.current_project as PixelPenProject).export_webp_image(file)
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(720, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)
