@tool
extends "tool.gd"


const zoom_in_texture := preload("../../resources/icon/zoom_in_24.svg")
const zoom_out_texture := preload("../../resources/icon/zoom_out_24.svg")

var hold : bool = false
var pressed_moused_position : Vector2
var shift_mode : bool = false


func _init():
	tool_type =  PixelPen.ToolBox.TOOL_ZOOM
	active_sub_tool_type = PixelPen.ToolZoom.TOOL_ZOOM_IN
	has_shift_mode = true


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	var prev_mouse_offset = node.camera.get_local_mouse_position()
			
	var zoom_scale : float = 0.0
	if active_sub_tool_type == PixelPen.ToolZoom.TOOL_ZOOM_IN:
		zoom_scale = -0.2 if shift_mode else 0.2
	elif active_sub_tool_type == PixelPen.ToolZoom.TOOL_ZOOM_OUT:
		zoom_scale = 0.2 if shift_mode else -0.2
		
	node.camera.zoom += node.camera.zoom * zoom_scale
	
	var current_mouse_offset = node.camera.get_local_mouse_position()
	node.camera.offset -= current_mouse_offset - prev_mouse_offset
	node.queue_redraw()
	
	hold = true
	pressed_moused_position = node.to_local(node.get_global_mouse_position())
	if node.selection_tool_hint.texture != null:
		node.selection_tool_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
		node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	hold = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if hold:
		node.camera.offset -= node.to_local(node.get_global_mouse_position()) - pressed_moused_position
		node.queue_redraw()


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed
	PixelPen.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	if active_sub_tool_type == PixelPen.ToolZoom.TOOL_ZOOM_IN:
		draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, zoom_out_texture if shift_mode else zoom_in_texture)
	elif active_sub_tool_type == PixelPen.ToolZoom.TOOL_ZOOM_OUT:
		draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, zoom_in_texture if shift_mode else zoom_out_texture)
