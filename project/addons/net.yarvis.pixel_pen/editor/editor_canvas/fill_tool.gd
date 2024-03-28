@tool
extends "tool.gd"


const texture := preload("../../resources/icon/ink_24.svg")

static var fill_grow_only_axis : bool = true

var shift_mode : bool = false


func _init():
	tool_type = PixelPen.ToolBox.TOOL_FILL
	has_shift_mode = true


func _on_sub_tool_changed(type : int):
	if type == PixelPen.ToolBoxFill.TOOL_FILL_OPTION_ONLY_AXIS_YES:
		fill_grow_only_axis = true
	elif type == PixelPen.ToolBoxFill.TOOL_FILL_OPTION_ONLY_AXIS_NO:
		fill_grow_only_axis = false
	else:
		super._on_sub_tool_changed(type)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image != null:
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
			var coords = floor(mouse_position)
			if mask_selection.get_pixel(coords.x, coords.y).r8 == 0:
				return 
		else:
			var coord : Vector2i = floor(mouse_position)
			if index_image.coor_inside_canvas(coord.x, coord.y):
				var mask : Image = PixelPen.utils.get_mask_flood(
					coord,
					index_image.colormap,
					Vector2i.ONE,
					fill_grow_only_axis
				)
				if not mask.is_empty():
					mask_selection = MaskSelection.get_image_no_margin(mask)
				
		(PixelPen.current_project as PixelPenProject).create_undo_layers("Paint", func ():
				PixelPen.layer_items_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		index_image.fill_index_on_color_map(_index_color, mask_selection)
		if node.selection_tool_hint.texture != null:
			var mirror_line : Vector2i
			if node.show_symetric_vertical:
				mirror_line.x = node.symetric_guid.x
			if node.show_symetric_horizontal:
				mirror_line.y = node.symetric_guid.y
			if mirror_line != Vector2i.ZERO:
				index_image.fill_index_on_color_map(
						_index_color, 
						get_mirror_image(mirror_line, mask_selection))
		(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
				PixelPen.layer_items_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
		(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
		callback.call()


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed
	PixelPen.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_color_picker_cursor(mouse_position)
		return
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, texture)
