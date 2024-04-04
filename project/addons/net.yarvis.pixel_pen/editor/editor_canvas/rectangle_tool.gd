@tool
extends "tool.gd"


const texture := preload("../../resources/icon/rect_24.svg")

var start_pressed_position : Vector2
var end_pressed_position : Vector2

var _draw_rect_hint : bool = false
var shift_mode : bool = false


func _init():
	tool_type = PixelPen.ToolBox.TOOL_RECTANGLE
	has_shift_mode = true


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		return
	is_pressed = true
	_draw_rect_hint = false
	start_pressed_position = mouse_position


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	var start := round(start_pressed_position) as Vector2i 
	var end := round(end_pressed_position) as Vector2i
	var rect = Rect2i(start, end - start).abs()
	rect = rect.intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
	
	if _draw_rect_hint and rect.size != Vector2i.ZERO:
		(PixelPen.current_project as PixelPenProject).create_undo_layers("Paint", func ():
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		paint_rect(rect, _index_color, mask_selection)
		if node.show_symetric_vertical:
			var offset_x = node.symetric_guid.x + node.symetric_guid.x - rect.end.x
			var v_rect = Rect2i(Vector2i(offset_x, rect.position.y), rect.size).intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
			paint_rect(v_rect, _index_color, mask_selection)
			if node.show_symetric_horizontal:
				var offset_y = node.symetric_guid.y + node.symetric_guid.y - v_rect.end.y
				var h_rect = Rect2i(Vector2i(v_rect.position.x, offset_y), v_rect.size).intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
				paint_rect(h_rect, _index_color, mask_selection)
		if node.show_symetric_horizontal:
			var offset_y = node.symetric_guid.y + node.symetric_guid.y - rect.end.y
			var h_rect = Rect2i(Vector2i(rect.position.x, offset_y), rect.size).intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
			paint_rect(h_rect, _index_color, mask_selection)
		(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
		callback.call()
	
	is_pressed = false
	_draw_rect_hint = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if shift_mode:
		return
	end_pressed_position = mouse_position
	var start = round(start_pressed_position)
	var end = round(end_pressed_position)
	_draw_rect_hint = is_pressed and start != end


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed and not is_pressed
	PixelPen.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_color_picker_cursor(mouse_position)
		return
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, texture)


func _on_draw_hint(mouse_position : Vector2):
	if _draw_rect_hint:
		var start = round(start_pressed_position)
		var end = round(end_pressed_position)
		var rect = Rect2i(start, end - start)
		node.draw_rect(rect, Color.WHITE, false)
		draw_circle_marker(start)
		draw_circle_marker(end)
		draw_circle_marker(Vector2(end.x, start.y))
		draw_circle_marker(Vector2(start.x, end.y))
	elif is_pressed:
		var start = round(start_pressed_position)
		draw_circle_marker(start)
