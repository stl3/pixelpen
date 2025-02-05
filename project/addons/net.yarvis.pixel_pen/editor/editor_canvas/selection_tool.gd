@tool
extends "tool.gd"


const selection_union = preload("../../resources/icon/vector-union.svg")
const selection_difference = preload("../../resources/icon/vector-difference-ba.svg")
const selection_intersection = preload("../../resources/icon/vector-intersection.svg")

static var sub_tool_selection_type : int:
	get:
		var yes := sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION
		yes = yes or sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE
		yes = yes or sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION
		if not yes:
			sub_tool_selection_type = PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION
		return sub_tool_selection_type
static var has_pre_selection_polygon : bool = false
var pre_selection_polygon : PackedVector2Array

var _selection_image : Image


func _init():
	tool_type = PixelPen.ToolBox.TOOL_SELECTION
	active_sub_tool_type = sub_tool_selection_type
	has_shift_mode = false


func _on_sub_tool_changed(type: int):
	if type == PixelPen.ToolBoxSelection.TOOL_SELECTION_REMOVE:
		_selection_image = null
		create_undo()
		build_hint_image()
		create_redo()
	elif type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED:
		delete_on_selected()
	elif has_pre_selection_polygon and type == PixelPen.ToolBoxSelection.TOOL_SELECTION_CLOSE_POLYGON:
		pre_selection_polygon.push_back(pre_selection_polygon[0])
		_create_selection()
	else:
		super._on_sub_tool_changed(type)
	var yes := active_sub_tool_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION
	yes = yes or active_sub_tool_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE
	yes = yes or active_sub_tool_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION
	if yes:
		sub_tool_selection_type = active_sub_tool_type


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if node.selection_tool_hint.texture != null:
		_selection_image = node.selection_tool_hint.texture.get_image()
	var point : Vector2 = round(mouse_position)
	if pre_selection_polygon.has(point):
		if pre_selection_polygon.size() >= 3 and pre_selection_polygon[0] == point:
			pre_selection_polygon.push_back(point)
			_create_selection()
	else:
		pre_selection_polygon.push_back(point)
	is_pressed = true and pre_selection_polygon.size() == 1
	has_pre_selection_polygon = pre_selection_polygon.size() >= 3


func _on_mouse_released(mouse_position : Vector2, _callback : Callable):
	if is_pressed:
		if pre_selection_polygon.size() == 2:
			var size = pre_selection_polygon[1] - pre_selection_polygon[0]
			pre_selection_polygon.insert(1, pre_selection_polygon[0] + Vector2(size.x, 0))
			pre_selection_polygon.push_back(pre_selection_polygon[0] + Vector2(0, size.y))
			pre_selection_polygon.push_back(pre_selection_polygon[0])
			_create_selection()
		is_pressed = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if is_pressed and round(mouse_position) != pre_selection_polygon[0]:
		if pre_selection_polygon.size() == 2:
			pre_selection_polygon[1] = round(mouse_position)
		if pre_selection_polygon.size() == 1:
			pre_selection_polygon.push_back(round(mouse_position))


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	var texture : Texture2D
	match sub_tool_selection_type:
		PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION:
			texture = selection_union
		PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
			texture = selection_difference
		PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
			texture = selection_intersection
	if texture != null:
		draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, texture)


func _on_draw_hint(mouse_position : Vector2):
	var draw_unclosed = pre_selection_polygon.size() > 0 and pre_selection_polygon[0] != pre_selection_polygon[pre_selection_polygon.size()-1]
	if is_pressed:
		_draw_rect_selection(mouse_position)
	elif (draw_unclosed or pre_selection_polygon.size() == 1):
		_draw_unclosed_selection(mouse_position)


func _draw_unclosed_selection(mouse_position : Vector2):
	for i in range(pre_selection_polygon.size()):
		if i > 0:
			node.draw_line(pre_selection_polygon[i-1], pre_selection_polygon[i], Color.WHITE)
		draw_circle_marker(pre_selection_polygon[i])
		if i == pre_selection_polygon.size() -1:
			node.draw_line(pre_selection_polygon[i], mouse_position, Color.WHITE)


func _draw_rect_selection(mouse_position : Vector2):
	draw_circle_marker(pre_selection_polygon[0])
	if pre_selection_polygon.size() == 2:
		var size = pre_selection_polygon[1] - pre_selection_polygon[0]
		draw_circle_marker(pre_selection_polygon[0] + Vector2(size.x, 0))
		draw_circle_marker(pre_selection_polygon[1])
		draw_circle_marker(pre_selection_polygon[0] + Vector2(0, size.y))
		node.draw_rect(Rect2(pre_selection_polygon[0], size), Color.WHITE, false)


func _create_selection():
	if active_sub_tool_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION:
		var new_selection_image := MaskSelection.create_image(pre_selection_polygon, node.canvas_size)
		if _selection_image == null:
			_selection_image = new_selection_image
		else:
			_selection_image = MaskSelection.union_image(_selection_image, new_selection_image)
		
	elif active_sub_tool_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
		if _selection_image != null:
			_selection_image = MaskSelection.difference_image(
					_selection_image, MaskSelection.create_image(pre_selection_polygon, node.canvas_size))
	elif active_sub_tool_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
		if _selection_image != null:
			_selection_image = MaskSelection.intersection_image(_selection_image, 
					MaskSelection.create_image(pre_selection_polygon, node.canvas_size))
	pre_selection_polygon.clear()
	has_pre_selection_polygon = false
	create_undo()
	build_hint_image()
	create_redo()


func build_hint_image():
	if _selection_image != null:
		if node.selection_tool_hint.texture == null:
			var img_tex = ImageTexture.create_from_image(_selection_image)
			node.selection_tool_hint.texture = img_tex
		else:
			node.selection_tool_hint.texture.update(_selection_image)
		node.selection_tool_hint.offset = -Vector2.ONE
		node.selection_tool_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
	else:
		node.selection_tool_hint.texture = null


func create_undo():
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


func create_redo():
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
