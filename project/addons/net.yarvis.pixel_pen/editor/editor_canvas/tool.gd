@tool
extends RefCounted


static var node : Node2D
static var active_tool_type : PixelPen.ToolBox = PixelPen.ToolBox.TOOL_UNKNOWN
static var active_sub_tool_type : int = -1
static var tool_type : int = PixelPen.ToolBox.TOOL_UNKNOWN ## current class
static var has_shift_mode : bool = false
static var is_pressed : bool = false
static var _index_color : int
static var _can_draw : bool = false
static var _prev_paint_coord : Vector2
static var _prev_paint_coord3 : PackedVector2Array
static var _prev_replaced_color3 : PackedInt32Array
static var _prev_paint_coord_array : PackedVector2Array

const color_picker_texture := preload("../../resources/icon/color_picker_24.svg")
const pan_texture := preload("../../resources/icon/pan_24.svg")


func _init():
	tool_type = PixelPen.ToolBox.TOOL_UNKNOWN
	has_shift_mode = false


func _on_request_switch_tool(tool_box_type : int) -> bool:
	return true


func _on_sub_tool_changed(type : int):
	if type == PixelPen.ToolBoxSelection.TOOL_SELECTION_REMOVE:
		if tool_type == PixelPen.ToolBox.TOOL_MOVE:
			node.canvas_paint.tool._on_move_cancel()
			node.canvas_paint.tool.mask_selection = null
		node.selection_tool_hint.texture = null
	elif type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED:
		delete_on_selected()
	else:
		active_sub_tool_type = type


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	pass


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	pass


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	pass


func _on_shift_pressed(pressed : bool):
	pass


func _on_draw_cursor(mouse_position : Vector2):
	draw_invalid_cursor(mouse_position)


func _on_draw_hint(mouse_position : Vector2):
	pass


func pick_color_from_canvas(mouse_position : Vector2, emit_color_picked : bool = true) -> int:
	var index_image = (PixelPen.current_project as PixelPenProject).index_image
	var coord : Vector2 = floor(mouse_position)
		
	var size = index_image.size()
		
	if size == 0 or not index_image[0].coor_inside_canvas(coord.x, coord.y):
		return -1
		
	var pallete_idx : int = 0
	for i in range(size - 1, -1, -1):
		if index_image[i].visible and PixelPen.current_project.palette.color_index[index_image[i].colormap.get_pixel(coord.x, coord.y).r8].a > 0:
			pallete_idx = index_image[i].colormap.get_pixel(coord.x, coord.y).r8
			break
	if pallete_idx != 0 and emit_color_picked:
		PixelPen.color_picked.emit(pallete_idx)
		PixelPen.palette_changed.emit() # rebuild grid palette
	return pallete_idx


func paint_line(from : Vector2, to : Vector2, color_index : int, no_double : bool = false):
	if floor(from) == floor(to):
		paint_pixel(from, color_index, no_double)
		return
	for i in range(ceil( from.distance_to(to)) ):
		var direction = from.direction_to(to)
		var coord = floor(from) + Vector2(0.5, 0.5) + direction * i
		paint_pixel(coord, color_index, no_double)


func paint_rect(rect : Rect2i, color_index : int, mask : Image = null):
	if not _can_draw:
		return false
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image != null:
		if index_image.rect_inside_canvas(rect):
			index_image.set_index_rect_on_color_map(rect, color_index, mask)
	else:
		_can_draw = false


func paint_pixel(pos : Vector2, color_index : int, no_double : bool = false):
	if not _can_draw:
		return false
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image != null:
		var coord = floor(pos)
		var ignore_like_prev_coor = (no_double and coord != floor(_prev_paint_coord))
		ignore_like_prev_coor = ignore_like_prev_coor or not no_double
		if index_image.coor_inside_canvas(coord.x, coord.y) and ignore_like_prev_coor:
			_prev_replaced_color3.push_back(index_image.get_index_on_color_map(coord.x, coord.y))
			_prev_replaced_color3 = _prev_replaced_color3.slice(-3)
			index_image.set_index_on_color_map(coord.x, coord.y, color_index)
			if not _prev_paint_coord_array.has(coord):
				_prev_paint_coord_array.push_back(coord)
			_prev_paint_coord3.push_back(coord)
			_prev_paint_coord3 = _prev_paint_coord3.slice(-3)
			if _prev_paint_coord3.size() == 3 and no_double:
				var no : bool = _prev_paint_coord3[0].x != _prev_paint_coord3[2].x and _prev_paint_coord3[0].y != _prev_paint_coord3[2].y
				no = no and (_prev_paint_coord3[2].x == _prev_paint_coord3[1].x or _prev_paint_coord3[2].y == _prev_paint_coord3[1].y)
				if no and _prev_paint_coord3[2].distance_to(_prev_paint_coord3[0]) < 1.5:
					_prev_paint_coord_array.remove_at(_prev_paint_coord_array.find(_prev_paint_coord3[1]))
					index_image.set_index_on_color_map(_prev_paint_coord3[1].x, _prev_paint_coord3[1].y, _prev_replaced_color3[1])
					_prev_paint_coord3.remove_at(1)
					_prev_replaced_color3.remove_at(1)
	else:
		_can_draw = false
	_prev_paint_coord = floor(pos) + Vector2(0.5, 0.5)


func delete_on_selected():
	if node.selection_tool_hint.texture != null and PixelPen.current_project != null:
		var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
		if index_image != null:
			var mask = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
			(PixelPen.current_project as PixelPenProject).create_undo_layers("Paint", func ():
					PixelPen.layer_items_changed.emit()
					(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
					)
			index_image.empty_index_on_color_map(mask)
			node._update_shader_layer()
			(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
				PixelPen.layer_items_changed.emit()
				(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
				)
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)


func get_mirror_image(line : Vector2i, src_image : Image):
	var base : Image = Image.create(src_image.get_width(), src_image.get_height(), false, src_image.get_format())
	if line.x != 0:
		var x_flip : Image = src_image.duplicate()
		x_flip.flip_x()
		var region_x_size : int
		var region_x_position : int
		var blend_offset_x : int
		if line.x > src_image.get_width() * 0.5:
			region_x_size = 2 * (src_image.get_width() - line.x)
			region_x_position = 0
			blend_offset_x = src_image.get_width() - region_x_size
		else:
			region_x_size = 2 * line.x
			region_x_position = src_image.get_width() - region_x_size
			blend_offset_x = 0
		var region : Rect2i = Rect2i(Vector2i(region_x_position, 0), Vector2i(region_x_size, x_flip.get_height()))
		x_flip = x_flip.get_region(region)
		PixelPen.utils.blend(base, x_flip, Vector2i(blend_offset_x, 0))
		if line.y != 0:
			var y_flip : Image = base.duplicate()
			y_flip.flip_y()
			var region_y_size : int
			var region_y_position : int
			var blend_offset_y : int
			if line.y > src_image.get_height() * 0.5:
				region_y_size = 2 * (src_image.get_height() - line.y)
				region_y_position = 0
				blend_offset_y = src_image.get_height() - region_y_size
			else:
				region_y_size = 2 * line.y
				region_y_position = src_image.get_height() - region_y_size
				blend_offset_y = 0
			region = Rect2i(Vector2i(0, region_y_position), Vector2i(y_flip.get_width(), region_y_size))
			y_flip = y_flip.get_region(region)
			PixelPen.utils.blend(base, y_flip, Vector2i(0, blend_offset_y))
	if line.y != 0:
		var y_flip : Image = src_image.duplicate()
		y_flip.flip_y()
		var region_y_size : int
		var region_y_position : int
		var blend_offset_y : int
		if line.y > src_image.get_height() * 0.5:
			region_y_size = 2 * (src_image.get_height() - line.y)
			region_y_position = 0
			blend_offset_y = src_image.get_height() - region_y_size
		else:
			region_y_size = 2 * line.y
			region_y_position = src_image.get_height() - region_y_size
			blend_offset_y = 0
		var region : Rect2i = Rect2i(Vector2i(0, region_y_position), Vector2i(y_flip.get_width(), region_y_size))
		y_flip = y_flip.get_region(region)
		PixelPen.utils.blend(base, y_flip, Vector2i(0, blend_offset_y))
	return base


func get_ink_color() -> Color:
	if PixelPen.current_project == null:
		return Color.BLACK
	return PixelPen.current_project.palette.color_index[_index_color]


func get_viewport_scale(size : float):
	return (node.get_viewport_transform().affine_inverse() * size).x.x


func draw_circle_cursor(mouse_position : Vector2):
	node.draw_arc(mouse_position, 0.5, 0, TAU, 100, Color.BLACK)


func draw_circle_marker(position : Vector2):
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 10.0).x.x
	node.draw_arc(position, cursor_length, 0, TAU, 64, Color.WHITE)


func draw_cross_cursor(mouse_position : Vector2):
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	node.draw_line(mouse_position - Vector2(cursor_length, 0), mouse_position - Vector2(cursor_length, 0) * 0.4, Color.BLACK)
	node.draw_line(mouse_position + Vector2(cursor_length, 0), mouse_position + Vector2(cursor_length, 0) * 0.4, Color.BLACK)
	node.draw_line(mouse_position - Vector2(0, cursor_length), mouse_position - Vector2(0, cursor_length) * 0.4, Color.BLACK)
	node.draw_line(mouse_position + Vector2(0, cursor_length), mouse_position + Vector2(0, cursor_length) * 0.4, Color.BLACK)


func draw_plus_cursor(mouse_position : Vector2, size : float = 10.0):
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * size).x.x
	node.draw_line(mouse_position - Vector2(cursor_length, 0), mouse_position + Vector2(cursor_length, 0), Color.BLACK)
	node.draw_line(mouse_position - Vector2(0, cursor_length), mouse_position + Vector2(0, cursor_length), Color.BLACK)


func draw_color_picker_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, color_picker_texture)


func draw_pan_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, pan_texture)


func draw_invalid_cursor(mouse_position : Vector2, size : float = 10.0):
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * size).x.x
	node.draw_arc(mouse_position, cursor_length, 0, TAU, 100, Color.RED, 0.2 * cursor_length)
	var line = Vector2(cursor_length, 0).rotated(PI * -0.25)
	node.draw_line(mouse_position - line, mouse_position + line, Color.RED, 0.2 * cursor_length)


func draw_texture(position : Vector2, texture : Texture2D, scaled : bool = true):
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	if not scaled:
		cursor_length = 0.2
	var rect = Rect2(position, Vector2.ONE * cursor_length)
	node.draw_texture_rect(texture, rect, false, Color(1,1,1,0.75))
