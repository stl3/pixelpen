@tool
extends SubViewportContainer


@export var editor_canvas : Node2D


func _ready():
	if not PixelPen.need_connection(get_window()):
		return


func _input(event):
	if not PixelPen.need_connection(get_window()):
		return
	if Engine.is_editor_hint():
		editor_canvas._input(event)


func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			# grab focus back from line edit
			grab_focus()


func _on_mouse_entered():
	if PixelPen.current_project != null and get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if PixelPen.current_project != null and not PixelPen.current_project.active_layer_is_valid():
		editor_canvas.canvas_paint.tool._can_draw = false


func _on_mouse_exited():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
