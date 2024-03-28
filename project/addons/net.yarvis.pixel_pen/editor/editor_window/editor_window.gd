@tool
extends Window


const EditorMainUI := preload("../editor_main_ui.tscn")

var window_running : bool = false


func is_window_running():
	return window_running


func _ready():
	if is_window_running():
		add_child(EditorMainUI.instantiate(1))


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_window().window_running = false
		PixelPen.current_project = null
		get_window().queue_free()


func scan():
	if Engine.is_editor_hint() and type_exists("EditorInterface"):
		var efs = EditorInterface.get_resource_filesystem()
		efs.scan()
