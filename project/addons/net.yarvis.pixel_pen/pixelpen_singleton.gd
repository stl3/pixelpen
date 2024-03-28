@tool
#class_name PixelPen
extends Node


signal theme_changed

signal debug_log(key, value)
signal project_file_changed
signal palette_changed
signal color_picked(color)
signal dialog_visibled(visible)
signal layer_active_changed(uid)
signal layer_visibility_changed(uid, visible)
signal layer_items_changed
signal thumbnail_changed
signal edit_mode_changed(mode)

signal request_new_project
signal request_open_project
signal request_save_project
signal request_save_as_project
signal request_layer_properties(layer_uuid)

signal tool_changed(tool_grup, tool_type, grab_active)
signal toolbox_just_changed
signal toolbox_shift_mode(active)


const EDITOR_TITTLE = "Pixel Pen"
const uuid = preload("thirdparty/uuid/uuid.gd")

const ACCENT_COLOR = Color(0.25, 1, 0.5)
const LABEL_COLOR = Color(1, 1, 1)


enum ToolBoxGrup{
	TOOL_GRUP_UNKNOWN = -1,
	TOOL_GRUP_TOOLBOX,
	TOOL_GRUP_TOOLBOX_SUB_TOOL,
	TOOL_GRUP_LAYER
}

enum ToolBox{
	TOOL_UNKNOWN = -1,
	TOOL_SELECT,
	TOOL_MOVE,
	TOOL_PAN,
	TOOL_SELECTION,
	TOOL_PEN,
	TOOL_BRUSH,
	TOOL_ERASER,
	TOOL_LINE,
	TOOL_RECTANGLE,
	TOOL_FILL,
	TOOL_COLOR_PICKER,
	TOOL_ZOOM
}


enum ToolBoxSelect{
	TOOL_SELECT_UNKNOWN = -1,
	TOOL_SELECT_LAYER,
	TOOL_SELECT_COLOR,
	TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_YES,
	TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_NO
}


enum ToolBoxMove{
	TOOL_MOVE_UNKNOWN = -1,
	TOOL_MOVE_ROTATE_LEFT,
	TOOL_MOVE_ROTATE_RIGHT,
	TOOL_MOVE_FLIP_HORIZONTAL,
	TOOL_MOVE_FLIP_VERTICAL,
	TOOL_MOVE_CANCEL,
	TOOL_MOVE_COMMIT,
	TOOL_SCALE_LEFT,
	TOOL_SCALE_UP,
	TOOL_SCALE_RIGHT,
	TOOL_SCALE_DOWN
}

enum ToolBoxSelection{
	TOOL_SELECTION_UNKNOWN = -1,
	TOOL_SELECTION_UNION,
	TOOL_SELECTION_DIFFERENCE,
	TOOL_SELECTION_INTERSECTION,
	TOOL_SELECTION_CLOSE_POLYGON,
	TOOL_SELECTION_REMOVE = 1001, # GLOBAL UNIQUE
	TOOL_SELECTION_DELETE_SELECTED = 1002 # GLOBAL UNIQUE
}

enum ToolBoxPen{
	TOOL_PEN_UNKNOWN = -1,
	TOOL_PEN_PIXEL_PERFECT_YES,
	TOOL_PEN_PIXEL_PERFECT_NO
}


enum ToolBoxLine{
	TOOL_LINE_UNKNOWN = -1,
	TOOL_LINE_PIXEL_PERFECT_YES,
	TOOL_LINE_PIXEL_PERFECT_NO
}


enum ToolBoxFill{
	TOOL_FILL_UNKNOWN = -1,
	TOOL_FILL_OPTION_ONLY_AXIS_YES,
	TOOL_FILL_OPTION_ONLY_AXIS_NO
}


enum ToolZoom{
	TOOL_LINE_UNKNOWN = -1,
	TOOL_ZOOM_IN,
	TOOL_ZOOM_OUT,
}


enum ResizeAnchor{
	CENTER = 0,
	TOP_LEFT,
	TOP,
	TOP_RIGHT,
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM,
	BOTTOM_LEFT,
	LEFT
}


var current_project : PixelPenProject:
	set(v):
		current_project = v
		if v != null and v.file_path != "":
			save_cache_project_config()

var recent_projects : Array = []

var utils : PixelPenCPP = PixelPenCPP.new()
var userconfig : UserConfig:
	get:
		if userconfig == null:
			userconfig = UserConfig.load_data()
		return userconfig


func load_project(file : String)->bool:
	var res = ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res and res is PixelPenProject:
		current_project = res
		current_project.is_saved = true
		project_file_changed.emit()
		if not recent_projects.has(file):
			recent_projects.push_back(file)
			if recent_projects.size() > 10:
				recent_projects = recent_projects.slice(recent_projects.size() - 10)
			save_cache_project_config()
		return true
	return false


func save_cache_project_config():
	var config = ConfigFile.new()
	var p_path = ""
	if current_project != null:
		p_path = current_project.file_path
	config.set_value("Project", "last_open_path", p_path)
	config.set_value("Project", "Recents", recent_projects)
	config.save("user://PixelPen.cfg")


func load_cache_project() -> bool:
	var config = ConfigFile.new()

	var err = config.load("user://PixelPen.cfg")

	if err != OK:
		return false

	if config.has_section("Project"):
		recent_projects = config.get_value("Project", "Recents", [])
		var last_open_path = config.get_value("Project", "last_open_path", "")
		if last_open_path != "":
			return load_project(last_open_path)
	return false

## Prevent running in development mode
func need_connection(window : Window):
	var need := false
	if window.has_method("is_window_running"):
		need = window.is_window_running()
	return need or not Engine.is_editor_hint()
	
	
	
	
	
