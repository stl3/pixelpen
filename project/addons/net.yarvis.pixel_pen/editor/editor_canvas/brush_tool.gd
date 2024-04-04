@tool
extends "tool.gd"


static var brush_index : int = 0

var shift_mode : bool = false
var brush_color_map : Image
var brush_mask : ImageTexture


func _init():
	tool_type = PixelPen.ToolBox.TOOL_BRUSH
	has_shift_mode = true
	get_brush()


func _on_request_switch_tool(tool_box_type : int) -> bool:
	node.overlay_hint.texture = null
	node.overlay_hint.position = Vector2.ZERO
	node.overlay_hint.material.set_shader_parameter("enable", false)
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	get_brush()


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		return
	is_pressed = true
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	get_brush()
	if index_image != null and brush_color_map != null:
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
			
		(PixelPen.current_project as PixelPenProject).create_undo_layers("Paint", func ():
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				)
				
		var img : Image = index_image.colormap.duplicate()
		img.fill(Color8(0, 0, 0, 0))
		(img as Image).blend_rect(brush_color_map, brush_color_map.get_used_rect(), floor(mouse_position - brush_color_map.get_size() * 0.5))
		index_image.blit_color_map(img, mask_selection, Vector2i.ZERO)
		
		(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
		callback.call()


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	is_pressed = false


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed and not is_pressed
	PixelPen.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_color_picker_cursor(mouse_position)
		node.overlay_hint.visible = false
		return
	node.overlay_hint.visible = true
	if brush_color_map == null:
		draw_invalid_cursor(mouse_position)
	else:
		node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
		node.overlay_hint.material.set_shader_parameter("enable", true)
		node.overlay_hint.material.set_shader_parameter("marching_ant", false)
		node.overlay_hint.texture = brush_mask
		node.overlay_hint.position = floor(mouse_position - brush_mask.get_size() * 0.5)


func get_brush():
	if PixelPen.userconfig.brush.size() > brush_index and brush_index >= 0:
		var brush = PixelPen.userconfig.brush[brush_index]
		var size = brush.get_size()
		brush_color_map = Image.create(size.x, size.y, false, Image.FORMAT_R8)
		var mask = MaskSelection.create_empty(size)
		for x in range(size.x):
			for y in range(size.y):
				if brush.get_pixel(x, y).a8 > 0:
					brush_color_map.set_pixel(x, y, Color8(_index_color, 0, 0, 0))
					mask.set_pixel(x + 1, y + 1, Color.WHITE)
		brush_mask = ImageTexture.create_from_image(mask)
