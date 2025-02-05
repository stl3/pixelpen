@tool
extends "tool.gd"


const SelectionTool = preload("selection_tool.gd")

const selection_union = preload("../../resources/icon/vector-union.svg")
const selection_difference = preload("../../resources/icon/vector-difference-ba.svg")
const selection_intersection = preload("../../resources/icon/vector-intersection.svg")

const select_layer_texture = preload("../../resources/icon/layers-search-outline.svg")

static var selection_color_grow_only_axis : bool = true


func _init():
	tool_type = PixelPen.ToolBox.TOOL_SELECT
	active_sub_tool_type = PixelPen.ToolBoxSelect.TOOL_SELECT_LAYER
	has_shift_mode = false


func _on_sub_tool_changed(type : int):
	if type == PixelPen.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_YES:
		selection_color_grow_only_axis = true
	elif type == PixelPen.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_NO:
		selection_color_grow_only_axis = false
	else:
		super._on_sub_tool_changed(type)


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if active_sub_tool_type == PixelPen.ToolBoxSelect.TOOL_SELECT_COLOR:
		var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
		if index_image != null:
			var coord : Vector2i = floor(mouse_position)
			if index_image.coor_inside_canvas(coord.x, coord.y):
				var mask : Image = PixelPen.utils.get_mask_flood(
					coord,
					index_image.colormap,
					Vector2i.ONE,
					selection_color_grow_only_axis
				)
				if not mask.is_empty() and node.selection_tool_hint.texture != null:
					var selection_image = node.selection_tool_hint.texture.get_image()
					if SelectionTool.sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION:
						mask = MaskSelection.union_image(selection_image, mask)
					elif SelectionTool.sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
						mask = MaskSelection.difference_image(selection_image, mask)
					elif SelectionTool.sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
						mask = MaskSelection.intersection_image(selection_image, mask)
				if not mask.is_empty():
					create_undo_selection()
					node.selection_tool_hint.texture = ImageTexture.create_from_image(mask)
					create_redo_selection()
					node.selection_tool_hint.position = Vector2.ZERO
					node.selection_tool_hint.offset = -Vector2.ONE
					node.selection_tool_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
	elif active_sub_tool_type == PixelPen.ToolBoxSelect.TOOL_SELECT_LAYER:
		var index_images : Array[IndexedColorImage] = PixelPen.current_project.index_image
		var coord : Vector2 = floor(mouse_position)
		for i in range(index_images.size() - 1, -1, -1):
			var palette_idx : int = index_images[i].get_index_on_color_map(coord.x, coord.y)
			var color : Color = (PixelPen.current_project as PixelPenProject).palette.color_index[palette_idx]
			if color.a > 0:
				var layer_uuid = index_images[i].layer_uuid
				PixelPen.layer_active_changed.emit(layer_uuid)
				break


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	if active_sub_tool_type == PixelPen.ToolBoxSelect.TOOL_SELECT_COLOR:
		var texture : Texture2D
		match SelectionTool.sub_tool_selection_type:
			PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION:
				texture = selection_union
			PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
				texture = selection_difference
			PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
				texture = selection_intersection
		if texture != null:
			draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, texture)
		else:
			print(SelectionTool.sub_tool_selection_type)
	elif active_sub_tool_type == PixelPen.ToolBoxSelect.TOOL_SELECT_LAYER:
		draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, select_layer_texture)


func create_undo_selection():
	var selection_texture = node.selection_tool_hint.texture
	if selection_texture != null:
		selection_texture = selection_texture.duplicate(true)
	(PixelPen.current_project as PixelPenProject).create_undo_property(
			"Selection",
			node.selection_tool_hint,
			"texture",
			selection_texture,
			func ():pass,
			true
			)


func create_redo_selection():
	var selection_texture = node.selection_tool_hint.texture
	if selection_texture != null:
		selection_texture = selection_texture.duplicate(true)
	(PixelPen.current_project as PixelPenProject).create_redo_property(
			node.selection_tool_hint,
			"texture",
			selection_texture,
			func ():pass,
			true
			)
