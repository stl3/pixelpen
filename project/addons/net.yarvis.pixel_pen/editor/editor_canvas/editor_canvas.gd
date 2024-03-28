@tool
extends Node2D

const ShaderIndex := preload("../../resources/indexed_layer.gdshader")
const CanvasPaint := preload("canvas_paint.gd")

@export var tile_node : Node2D
@export var background_canvas : Node2D
@export var layers : Node2D
@export var camera : Camera2D
@export var overlay_hint : Sprite2D
@export var selection_tool_hint : Sprite2D
@export var filter : Sprite2D
@export var silhouette : bool = false
@export var show_grid : bool = false
@export var show_tile : bool = false
@export var show_symetric_vertical : bool = false
@export var show_symetric_horizontal : bool = false
@export var show_view_grayscale : bool = false:
	set(v):
		if filter:
			filter.material.set_shader_parameter("grayscale", v)
		show_view_grayscale = v
	get:
		if filter:
			return filter.material.get_shader_parameter("grayscale")
		else:
			return show_view_grayscale


var symetric_guid : Vector2
var canvas_paint = CanvasPaint.new(self)

var _queue_update_camera_zoom : bool = false
var _selection_blink : int = 0
var _symetric_guid_color_vertical : Color = Color.WHITE
var _symetric_guid_color_horizontal : Color = Color.WHITE
var _on_move_symetric_guid : bool = false
var _on_move_symetric_guid_type : int = -1
var _on_pan_shorcut_mode : bool = false
var _on_pan_shorcut_mode_pressed_moused_position : Vector2

var canvas_size : Vector2i


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.project_file_changed.connect(func ():
			_queue_update_camera_zoom = true
			_create_layers()
			selection_tool_hint.texture = null
			overlay_hint.texture = null
			overlay_hint.position = Vector2.ZERO
			selection_tool_hint.position = Vector2.ZERO
			selection_tool_hint.offset = -Vector2.ONE
			if PixelPen.current_project == null:
				canvas_paint.tool = canvas_paint.Tool.new()
			else:
				symetric_guid = canvas_size * 0.5
			update_filter_size()
			)
				
	PixelPen.layer_items_changed.connect(_create_layers)
	PixelPen.color_picked.connect(func(color_index):
			canvas_paint.tool._index_color = color_index
			_update_shader_layer()
			)
	PixelPen.layer_visibility_changed.connect(func(layer_uuid, visibility):
			var children = layers.get_children()
			for child in children:
				if child.get_meta("layer_uuid") == layer_uuid:
					child.visible = visibility
					if (PixelPen.current_project as PixelPenProject).active_layer_uuid == layer_uuid:
						canvas_paint.tool._can_draw = visibility
					break
			)
	PixelPen.layer_active_changed.connect(func(layer_uuid):
			var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).get_index_image(layer_uuid)
			if index_image != null:
				canvas_paint.tool._can_draw = index_image.visible
			)
	PixelPen.tool_changed.connect(func(grup, type, _grab_active):
			if grup == PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX:
				if canvas_paint.tool.active_tool_type != type:
					if await canvas_paint.tool._on_request_switch_tool(type):
						canvas_paint.tool.active_tool_type = type
					else:
						# cancel switch
						PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, canvas_paint.tool.active_tool_type, true)
			elif grup == PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL:
				canvas_paint.tool._on_sub_tool_changed(type)
			)
	PixelPen.thumbnail_changed.connect(_create_tiled)
	background_canvas.visible = PixelPen.current_project != null
	_queue_update_camera_zoom = true


func _process(_delta):
	if _queue_update_camera_zoom:
		update_camera_zoom()
	if Engine.get_frames_drawn() % 10 == 0:
		_selection_blink = mini(3 , _selection_blink + 1)
		if _selection_blink == 3:
			_selection_blink = 0
		queue_redraw()


func _physics_process(_delta):
	update_filter_size()


func update_filter_size():
	filter.scale = Vector2(1.0, 1.0)
	var new_texture = PlaceholderTexture2D.new()
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * -Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	var margin = Vector2(32, 32)
	new_texture.size = viewport_size - viewport_zero + margin
	filter.texture = new_texture
	filter.global_position = viewport_zero - margin * 0.5


func update_camera_zoom():
	if get_viewport_rect().size != Vector2.ZERO:
		if PixelPen.current_project != null:
			background_canvas.scale = PixelPen.current_project.canvas_size as Vector2
			
		_queue_update_camera_zoom = false
		var camera_scale_factor = get_viewport_rect().size / background_canvas.scale
		if camera_scale_factor.x < camera_scale_factor.y:
			camera.zoom = Vector2.ONE * camera_scale_factor.x * 0.8
		else:
			camera.zoom = Vector2.ONE * camera_scale_factor.y * 0.8
		camera.position = background_canvas.scale * 0.5
		camera.offset = Vector2.ZERO


func zoom(factor : float):
	var prev_mouse_offset = camera.get_local_mouse_position()
			
	var zoom_scale = factor - 1.0
	camera.zoom += camera.zoom * zoom_scale * 0.5
	
	var current_mouse_offset = camera.get_local_mouse_position()
	camera.offset -= current_mouse_offset - prev_mouse_offset
	queue_redraw()
	if selection_tool_hint.texture != null:
		selection_tool_hint.material.set_shader_parameter("zoom_bias", camera.zoom)
		overlay_hint.material.set_shader_parameter("zoom_bias", camera.zoom)


func pan(offset : Vector2):
	var w = clampf(camera.zoom.length(), 1, 30)
	camera.offset += offset * lerpf(10, 1, w / 30)
	queue_redraw()


func update_background_shader_state():
	background_canvas.material.set_shader_parameter("tile_size", (PixelPen.current_project as PixelPenProject).checker_size )
	background_canvas.visible = true


func _input(event: InputEvent):
	PixelPen.debug_log.emit("Input", event)
	if PixelPen.current_project == null:
		return
	
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT and event.is_released():
			canvas_paint.on_shift_pressed(event.is_pressed())
			queue_redraw()
	
	if event and get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		PixelPen.debug_log.emit("Cursor", floor(get_local_mouse_position()))
		if event is InputEventKey:
			if event.keycode == KEY_SHIFT:
				canvas_paint.on_shift_pressed(event.is_pressed())
				queue_redraw()
		
		if event and event is InputEventMagnifyGesture:
			zoom(event.factor)
		elif event and event is InputEventPanGesture:
			pan(event.delta)
		elif event and event is InputEventMouseButton:
			var is_hovered_symetric = _is_hovered_symetric_guid()
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
				_on_pan_shorcut_mode = true
				_on_pan_shorcut_mode_pressed_moused_position = to_local(get_global_mouse_position())
				queue_redraw()
			elif event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
				_on_pan_shorcut_mode = false
				queue_redraw()
			elif not _on_pan_shorcut_mode:
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					if is_hovered_symetric != -1:
						_on_move_symetric_guid = true
						_on_move_symetric_guid_type = is_hovered_symetric
					else:
						canvas_paint.on_mouse_pressed(get_local_mouse_position(), _update_shader_layer)
						queue_redraw()
					
				elif not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					if _on_move_symetric_guid:
						_on_move_symetric_guid = false
						_on_move_symetric_guid_type = -1
					else:
						canvas_paint.on_mouse_released(get_local_mouse_position(), _update_shader_layer)
						queue_redraw()
		if event and event is InputEventMouseMotion:
			if _on_pan_shorcut_mode:
				camera.offset -= to_local(get_global_mouse_position()) - _on_pan_shorcut_mode_pressed_moused_position
				queue_redraw()
			elif _on_move_symetric_guid:
				if _on_move_symetric_guid_type == 0:
					symetric_guid.x = round(get_local_mouse_position()).x
					symetric_guid.x = clamp(symetric_guid.x, 0, canvas_size.x)
				elif _on_move_symetric_guid_type == 1:
					symetric_guid.y = round(get_local_mouse_position()).y
					symetric_guid.y = clamp(symetric_guid.y, 0, canvas_size.y)
			else:
				canvas_paint.on_mouse_motion(get_local_mouse_position(), event.relative, _update_shader_layer)
		
	else:
		canvas_paint.on_mouse_released(get_local_mouse_position(), _update_shader_layer)
	
	if event and event is InputEventMouseMotion:
		queue_redraw()


func _draw():
	if get_window().has_focus() and PixelPen.current_project != null:
		canvas_paint.on_draw_hint(get_local_mouse_position())
		if get_viewport_rect().has_point(get_viewport().get_mouse_position()):
			var type_hovered = _is_hovered_symetric_guid()
			if type_hovered == -1:
				_symetric_guid_color_vertical.a = 1
				_symetric_guid_color_horizontal.a = 1
				if _on_pan_shorcut_mode:
					canvas_paint.tool.draw_pan_cursor(get_local_mouse_position())
				else:
					canvas_paint.on_draw_cursor(get_local_mouse_position())
			elif type_hovered == 0:
				_symetric_guid_color_vertical.a = 0.75
				canvas_paint.tool.draw_plus_cursor(get_local_mouse_position(), 15)
			elif type_hovered == 1:
				_symetric_guid_color_horizontal.a = 0.75
				canvas_paint.tool.draw_plus_cursor(get_local_mouse_position(), 15)
	if show_grid and PixelPen.current_project != null:
		_draw_grid(1, 0.07)
		_draw_grid(8, 0.075)
		_draw_grid(16, 0.1)
		_draw_grid(32, 0.125)
	if PixelPen.current_project != null:
		_draw_symetric_guid()
	if show_tile and PixelPen.current_project != null:
		draw_rect(Rect2i(Vector2.ZERO, canvas_size), Color.MAGENTA, false)


func _draw_grid(grid_size : int, alpha : float):
	var color = Color(1, 1, 1, alpha)
	for x in range(1 + canvas_size.x / grid_size):
		draw_line(Vector2(x * grid_size, 0), Vector2(x * grid_size, canvas_size.y), color)
	for y in range(1 + canvas_size.y / grid_size):
		draw_line(Vector2(0, y * grid_size), Vector2(canvas_size.x, y * grid_size), color)


func _draw_symetric_guid():
	if get_viewport_transform().affine_inverse().origin == Vector2(-1, -1):
		return
	var ca : float = 0.5
	
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	var radius_size : float = (get_viewport_transform().affine_inverse() * 10.0).x.x
	if show_symetric_vertical:
		var vertical_x_pos = floor(symetric_guid.x)
		draw_line(Vector2(vertical_x_pos, viewport_zero.y + radius_size), Vector2(vertical_x_pos, viewport_size.y), Color(1, 1, 1, ca))
		draw_circle(Vector2(vertical_x_pos, viewport_zero.y), radius_size, _symetric_guid_color_vertical)
	if show_symetric_horizontal:
		var horizontal_y_pos = floor(symetric_guid.y)
		draw_line(Vector2(viewport_zero.x + radius_size, horizontal_y_pos), Vector2(viewport_size.x, horizontal_y_pos), Color(1, 1, 1, ca))
		draw_circle(Vector2(viewport_zero.x, horizontal_y_pos), radius_size, _symetric_guid_color_horizontal)


func _is_hovered_symetric_guid() -> int:
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	var radius_size : float = (get_viewport_transform().affine_inverse() * 10.0).x.x
	
	var guid_v_pos = Vector2(floor(symetric_guid.x), viewport_zero.y)
	var guid_h_pos = Vector2(viewport_zero.x, floor(symetric_guid.y))
	if get_local_mouse_position().distance_to(guid_v_pos) < radius_size * 2:
		return 0
	elif get_local_mouse_position().distance_to(guid_h_pos) < radius_size * 2:
		return 1
	return -1
	


func _update_shader_layer():
	var palette : IndexedPalette = (PixelPen.current_project as PixelPenProject).palette
	var dirty_children = layers.get_children()
	var children : Array[Node] = []
	for child in dirty_children:
		if not child.is_queued_for_deletion():
			children.push_back(child)
	silhouette = false
	for i in children.size():
		var layer : Sprite2D = children[i]
		var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).get_index_image(layer.get_meta("layer_uuid"))
		if index_image != null:
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			mat.set_shader_parameter("silhouette", 1.0 if index_image.silhouette else 0.0)
			silhouette = silhouette or index_image.silhouette


func _create_layers():
	for child in layers.get_children():
		child.queue_free()
	if PixelPen.current_project == null:
		background_canvas.visible = false
		return
	update_background_shader_state()
	var size = (PixelPen.current_project as PixelPenProject).index_image.size()
	canvas_size = (PixelPen.current_project as PixelPenProject).canvas_size
	for i in range(size):
		_create_layer(i)
	_update_shader_layer()


func _create_layer(index : int):
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).index_image[index]
	var sprite = Sprite2D.new()
	sprite.texture = PlaceholderTexture2D.new()
	sprite.centered = false
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = ShaderIndex
	sprite.scale = index_image.size as Vector2
	sprite.visible = index_image.visible
	sprite.set_meta("layer_uuid", index_image.layer_uuid)
	layers.add_child(sprite)


func _create_tiled():
	for child in tile_node.get_children():
		child.queue_free()
	if not show_tile:
		return
	if PixelPen.current_project == null:
		return
	var image : Image = PixelPen.current_project.cache_thumbnail
	if image == null or image.is_empty():
		return
	var texture = ImageTexture.create_from_image(image)
	for x in range(-2, 3):
		for y in range(-2, 3):
			if x == 0 and y == 0:
				continue
			var sprite = Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.texture = texture
			sprite.centered = false
			sprite.position = texture.get_size() * Vector2(x, y)
			tile_node.add_child(sprite)
