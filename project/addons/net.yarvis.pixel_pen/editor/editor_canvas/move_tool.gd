@tool
extends "tool.gd"


signal confirm_dialog_closed

const texture := preload("../../resources/icon/move_24.svg")

enum Mode{
	UNKNOWN = -1,
	CUT,
	COPY
}

static var transformed : bool = false
static var mode : int = Mode.UNKNOWN
static var cache_move_transform : Vector2i
static var cache_move_transform_mask : Image

var default_selection_texture : Image
var default_cache_map : Image
var cut_cache_image_map : Image
var move_cache_image_map : Image
var mask_selection : Image

var _hold : bool = false

var _pressed_offset : Vector2
var _prev_offset : Vector2i
var _show_guid : bool = true
var _canvas_anchor_position : Vector2
var _rotate_anchor_offset : Vector2
var _is_rotate_anchor_hovered : bool = false
var _is_move_anchor : bool = false
var _mask_used_rect : Rect2i
var _cache_move_transform_start : Vector2i


func _init():
	tool_type = PixelPen.ToolBox.TOOL_MOVE
	if is_instance_valid(node):
		if node.selection_tool_hint.texture == null:
			default_selection_texture = null
			cache_move_transform_mask = null
		else:
			default_selection_texture = node.selection_tool_hint.texture.get_image().duplicate()
			cache_move_transform_mask = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
	
	cache_move_transform = Vector2.ZERO
	has_shift_mode = false


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if move_cache_image_map != null:
		var confirm_dialog : Window = ConfirmationDialog.new()
		confirm_dialog.title = PixelPen.EDITOR_TITTLE
		confirm_dialog.canceled.connect(func():
				_on_move_cancel()
				confirm_dialog_closed.emit()
				)
		confirm_dialog.confirmed.connect(func():
				_on_move_commit()
				confirm_dialog_closed.emit()
				)
		
		var description := Label.new()
		description.set_anchors_preset(Control.PRESET_FULL_RECT)
		description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.text = "Confirm transformation"
		confirm_dialog.add_child(description)
		
		node.owner.add_child(confirm_dialog)

		confirm_dialog.popup_centered(Vector2i(320, 128))
		await confirm_dialog_closed
	return move_cache_image_map == null


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	if type == PixelPen.ToolBoxMove.TOOL_MOVE_ROTATE_LEFT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_ROTATE_RIGHT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_LEFT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_UP:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_RIGHT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_DOWN:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_CANCEL:
		_on_move_cancel()
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_COMMIT:
		_on_move_commit()


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	_cache_move_transform_start = floor(mouse_position) as Vector2i
	_show_guid = true
	_pressed_offset = mouse_position
	if _is_rotate_anchor_hovered:
		_pressed_offset -= _rotate_anchor_offset
		_is_move_anchor = true
		return
	
	_hold = true
	_prev_offset = Vector2i( floor(node.overlay_hint.position.x), floor( node.overlay_hint.position.y))
	
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Paint", func ():
			PixelPen.layer_items_changed.emit()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	create_undo_overlay_position(node)
	
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
	if move_cache_image_map != null:
		index_image.colormap = cut_cache_image_map.duplicate()
		callback.call()
		return
		
	default_cache_map = index_image.colormap.duplicate()
	if node.selection_tool_hint.texture == null:
		mask_selection = null
	else:
		mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
	
	node.overlay_hint.texture = index_image.get_mipmap_texture(
		(PixelPen.current_project as PixelPenProject).palette,
		mask_selection
	)
	
	move_cache_image_map = index_image.get_color_map_with_mask(mask_selection)
	if mode != Mode.COPY:
		index_image.empty_index_on_color_map(mask_selection)
	cut_cache_image_map = index_image.get_color_map_with_mask().duplicate()
	callback.call()


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	cache_move_transform += (floor(mouse_position) as Vector2i) - _cache_move_transform_start
	if _is_move_anchor:
		_is_move_anchor = false
		return
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null or not _hold or move_cache_image_map == null:
		return
	index_image.colormap = cut_cache_image_map.duplicate()
	var offset = node.overlay_hint.position
	index_image.blit_color_map(move_cache_image_map, mask_selection, Vector2i(floor(offset.x), floor(offset.y)))
	if mask_selection != null:
		node.selection_tool_hint.offset = -Vector2.ONE
		create_undo_selection_position(node)
		node.selection_tool_hint.position = offset as Vector2
		create_redo_selection_position(node)
	create_redo_overlay_position(node)
	
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
	callback.call()
	
	_hold = false
	transformed = true


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if _is_move_anchor:
		_rotate_anchor_offset = mouse_position - _pressed_offset
		_rotate_anchor_offset.x = snappedf(_rotate_anchor_offset.x, 0.5)
		_rotate_anchor_offset.y = snappedf(_rotate_anchor_offset.y, 0.5)
		return
		
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null or not _hold or move_cache_image_map == null:
		return
	node.overlay_hint.position = (_prev_offset as Vector2) + floor(mouse_position) - floor(_pressed_offset)
	node.selection_tool_hint.offset = -Vector2.ONE + floor(mouse_position) - floor(_pressed_offset)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)
	if not _is_rotate_anchor_hovered:
		var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
		draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, texture)


func _on_draw_hint(mouse_position : Vector2):
	_draw_hint(mouse_position, true)


func _draw_hint(mouse_position : Vector2, draw_on_canvas : bool = false):
	if _show_guid:
		var offset = node.overlay_hint.position
		if mask_selection == null and node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		var guid_rect := Rect2()
		if mask_selection == null:
			if move_cache_image_map == null:
				guid_rect.size = (node.canvas_size as Vector2) + Vector2.ONE
				guid_rect.position = Vector2(-0.5, -0.5) + (offset as Vector2)
			else:
				guid_rect.size = (move_cache_image_map.get_size() as Vector2) + Vector2.ONE
				guid_rect.position = Vector2(-0.5, -0.5) + (offset as Vector2)
		else:
			if _mask_used_rect == Rect2i():
				_mask_used_rect = MaskSelection.get_mask_used_rect(mask_selection)
			guid_rect.size = (_mask_used_rect.size as Vector2) + Vector2.ONE
			guid_rect.position = (_mask_used_rect.position as Vector2) - Vector2(0.5, 0.5) + (offset as Vector2)
		
		if draw_on_canvas:
			node.draw_rect(guid_rect, Color.WHITE, false)
			draw_circle_marker(guid_rect.position)
			draw_circle_marker(guid_rect.end)
			draw_circle_marker(Vector2(guid_rect.end.x, guid_rect.position.y))
			draw_circle_marker(Vector2(guid_rect.position.x, guid_rect.end.y))
		
		# rotate anchor
		var cal = func():
			_canvas_anchor_position = _rotate_anchor_offset + guid_rect.position + guid_rect.size * 0.5
			_canvas_anchor_position.x = snappedf(_canvas_anchor_position.x, 0.5)
			_canvas_anchor_position.y = snappedf(_canvas_anchor_position.y, 0.5)
		
		cal.call()
		var xx = abs(fmod( snappedf(_canvas_anchor_position.x, 0.5) , 1 )) == 0.5
		var yy = abs(fmod( snappedf(_canvas_anchor_position.y, 0.5) , 1 )) == 0.5
		if xx and not yy:
			_rotate_anchor_offset.x -= 0.5
			cal.call()
		elif yy and not xx:
			_rotate_anchor_offset.y -= 0.5
			cal.call()
		
		_is_rotate_anchor_hovered = _canvas_anchor_position.distance_to(mouse_position) < get_viewport_scale(10)
		if _is_move_anchor:
			var distance = _canvas_anchor_position.distance_to(mouse_position)
			var direction = _canvas_anchor_position.direction_to(mouse_position)
			if draw_on_canvas:
				draw_plus_cursor(_canvas_anchor_position + direction * distance * 0.5, 20)
		elif draw_on_canvas:
			if _is_rotate_anchor_hovered:
				draw_plus_cursor(_canvas_anchor_position, 15)
			else:
				draw_plus_cursor(_canvas_anchor_position, 9)


func _transform(type : int):
	_show_guid = true
	_draw_hint(node.get_local_mouse_position())
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
	
	if node.selection_tool_hint.texture == null:
		mask_selection = null
	elif mask_selection == null:
		mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
	
	if node.overlay_hint.texture == null:
		node.overlay_hint.texture = index_image.get_mipmap_texture(
			(PixelPen.current_project as PixelPenProject).palette,
			mask_selection
		)
	
	if move_cache_image_map == null:
		default_cache_map = index_image.colormap.duplicate()
		move_cache_image_map = index_image.get_color_map_with_mask(mask_selection)
		if mode != Mode.COPY:
			index_image.empty_index_on_color_map(mask_selection)
		cut_cache_image_map = index_image.get_color_map_with_mask().duplicate()
	
	var angle
	var cw : int = - 1
	var origin_offset : Vector2
	var move_image : Image = node.overlay_hint.texture.get_image()
	var move_image_center_pos : Vector2 = _canvas_anchor_position - (move_image.get_size() as Vector2) * 0.5 - node.overlay_hint.position.round()

	move_image_center_pos -= _rotate_anchor_offset
	move_image_center_pos.x = snappedf(move_image_center_pos.x, 0.5)
	move_image_center_pos.y = snappedf(move_image_center_pos.y, 0.5)
	if type == PixelPen.ToolBoxMove.TOOL_MOVE_ROTATE_LEFT:
		angle = PI * -0.5
		cw = COUNTERCLOCKWISE
		var vector_tl_pos = Vector2(move_image.get_width() * -0.5, move_image.get_height() * -0.5)
		var vector_tr_pos = Vector2(move_image.get_width() * 0.5, move_image.get_height() * -0.5)
		var vector_rotated_tl_pos = vector_tr_pos.rotated(angle)
		move_image_center_pos = move_image_center_pos.rotated(angle) - move_image_center_pos
		origin_offset = vector_rotated_tl_pos - vector_tl_pos - move_image_center_pos

	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_ROTATE_RIGHT:
		angle = PI * 0.5
		cw = CLOCKWISE
		var vector_tl_pos = Vector2(move_image.get_width() * -0.5, move_image.get_height() * -0.5)
		var vector_bl_pos = Vector2(move_image.get_width() * -0.5, move_image.get_height() * 0.5)
		var vector_rotated_tl_pos = vector_bl_pos.rotated(angle)
		move_image_center_pos = move_image_center_pos.rotated(angle) - move_image_center_pos
		origin_offset = vector_rotated_tl_pos - vector_tl_pos - move_image_center_pos
		
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL:
		move_image.flip_x()
		move_cache_image_map.flip_x()
		
		move_image_center_pos.y = 0
		origin_offset = move_image_center_pos - move_image_center_pos * Vector2(-1, 0)
		var anchor : Vector2 = _rotate_anchor_offset * Vector2(-1, 1) - _rotate_anchor_offset
		origin_offset -= anchor
		
		_rotate_anchor_offset.x *= -1
		
	elif type == PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL:
		move_image.flip_y()
		move_cache_image_map.flip_y()
		
		move_image_center_pos.x = 0
		origin_offset = move_image_center_pos - move_image_center_pos * Vector2(0, -1)
		var anchor : Vector2 = _rotate_anchor_offset * Vector2(1, -1) - _rotate_anchor_offset
		origin_offset -= anchor
		
		_rotate_anchor_offset.y *= -1
	
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_LEFT:
		PixelPen.utils.move_shift(Vector2i(-1, 0), move_image)
		PixelPen.utils.move_shift(Vector2i(-1, 0), move_cache_image_map)
	
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_UP:
		PixelPen.utils.move_shift(Vector2i(0, -1), move_image)
		PixelPen.utils.move_shift(Vector2i(0, -1), move_cache_image_map)
	
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_RIGHT:
		PixelPen.utils.move_shift(Vector2i(1, 0), move_image)
		PixelPen.utils.move_shift(Vector2i(1, 0), move_cache_image_map)
		
	elif type == PixelPen.ToolBoxMove.TOOL_SCALE_DOWN:
		PixelPen.utils.move_shift(Vector2i(0, 1), move_image)
		PixelPen.utils.move_shift(Vector2i(0, 1), move_cache_image_map)
	
	if cw != -1:
		var anchor : Vector2 = _rotate_anchor_offset.rotated(angle) - _rotate_anchor_offset
		anchor.x = snappedf(anchor.x, 0.5)
		anchor.y = snappedf(anchor.y, 0.5)

		origin_offset -= anchor
	
		_rotate_anchor_offset = _rotate_anchor_offset.rotated(angle)
		_rotate_anchor_offset.x = snappedf(_rotate_anchor_offset.x, 0.5)
		_rotate_anchor_offset.y = snappedf(_rotate_anchor_offset.y, 0.5)
	
		move_image.rotate_90(cw)
		move_cache_image_map.rotate_90(cw)
	
	node.overlay_hint.texture = ImageTexture.create_from_image(move_image)
	node.overlay_hint.position += origin_offset
	node.overlay_hint.position = node.overlay_hint.position.round()
	
	if node.selection_tool_hint.texture != null:
		var mask_img = node.selection_tool_hint.texture.get_image()
		if cw != -1:
			mask_img.rotate_90(cw)
		elif type == PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL:
			mask_img.flip_x()
		elif type == PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL:
			mask_img.flip_y()
		elif type == PixelPen.ToolBoxMove.TOOL_SCALE_LEFT:
			PixelPen.utils.move_shift(Vector2i(-1, 0), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		elif type == PixelPen.ToolBoxMove.TOOL_SCALE_UP:
			PixelPen.utils.move_shift(Vector2i(0, -1), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		elif type == PixelPen.ToolBoxMove.TOOL_SCALE_RIGHT:
			PixelPen.utils.move_shift(Vector2i(1, 0), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		elif type == PixelPen.ToolBoxMove.TOOL_SCALE_DOWN:
			PixelPen.utils.move_shift(Vector2i(0, 1), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		node.selection_tool_hint.texture = ImageTexture.create_from_image(mask_img)
		mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		node.selection_tool_hint.position = node.overlay_hint.position.round()
	
	index_image.colormap = cut_cache_image_map.duplicate()
	var offset : Vector2 = node.overlay_hint.position
	index_image.blit_color_map(move_cache_image_map, mask_selection, Vector2i(round(offset.x), round(offset.y)))
	
	node._update_shader_layer()
	_mask_used_rect = Rect2i()
	_draw_hint(node.get_local_mouse_position())
	transformed = true


func _on_move_cancel():
	mode = Mode.UNKNOWN
	_rotate_anchor_offset = Vector2.ZERO
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null or move_cache_image_map == null:
		return
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Paint", func ():
			PixelPen.layer_items_changed.emit()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	index_image.colormap = default_cache_map.duplicate()
	if mask_selection != null:
		create_undo_selection_position(node)
		node.selection_tool_hint.position = Vector2.ZERO
		create_redo_selection_position(node)
	create_undo_overlay_position(node)
	node.overlay_hint.position = Vector2.ZERO
	create_redo_overlay_position(node)
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
	node._update_shader_layer()
	move_cache_image_map = null
	node.selection_tool_hint.offset = -Vector2.ONE
	node.overlay_hint.texture = null
	if default_selection_texture != null:
		node.selection_tool_hint.texture = ImageTexture.create_from_image(default_selection_texture)
	reset()
	_draw_hint(node.get_local_mouse_position())
	_show_guid = false
	transformed = false


func _on_move_commit():
	mode = Mode.UNKNOWN
	_rotate_anchor_offset = Vector2.ZERO
	if move_cache_image_map == null:
		return
	move_cache_image_map = null
	if mask_selection != null and node.selection_tool_hint.texture != null:
		var offset = node.selection_tool_hint.position 
		node.selection_tool_hint.texture = ImageTexture.create_from_image(
				MaskSelection.offset_image(node.selection_tool_hint.texture.get_image(), offset, node.canvas_size))
	node.selection_tool_hint.position = Vector2.ZERO
	node.selection_tool_hint.offset = -Vector2.ONE
	node.overlay_hint.position = Vector2.ZERO
	node.overlay_hint.texture = null
	reset()
	_draw_hint(node.get_local_mouse_position())
	_show_guid = false
	transformed = false


func create_undo_selection_position(node : Node2D):
	(PixelPen.current_project as PixelPenProject).create_undo_property(
			"Selection",
			node.selection_tool_hint,
			"position",
			node.selection_tool_hint.position,
			func (): pass
			)


func create_redo_selection_position(node : Node2D):
	(PixelPen.current_project as PixelPenProject).create_redo_property(
			node.selection_tool_hint,
			"position",
			node.selection_tool_hint.position,
			func ():pass
			)


func create_undo_overlay_position(node : Node2D):
	(PixelPen.current_project as PixelPenProject).create_undo_property(
			"Overlay",
			node.overlay_hint,
			"position",
			node.overlay_hint.position,
			func ():pass
			)


func create_redo_overlay_position(node : Node2D):
	(PixelPen.current_project as PixelPenProject).create_redo_property(
			node.overlay_hint,
			"position",
			node.overlay_hint.position,
			func ():pass
			)


func reset():
	default_selection_texture = null
	default_cache_map = null
	cut_cache_image_map = null
	move_cache_image_map = null
	mask_selection = null

	_hold = false

	_pressed_offset = Vector2.ZERO
	_prev_offset = Vector2i.ZERO
	_show_guid = true
	_canvas_anchor_position = Vector2.ZERO
	_rotate_anchor_offset = Vector2.ZERO
	_is_rotate_anchor_hovered = false
	_is_move_anchor = false
	_mask_used_rect = Rect2i()
