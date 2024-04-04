@tool
extends Control


const COLOR_RECT_COLOR_NAME = "Color"
const X_TOTAL = 10
const I_TOTAL = 255

@export var color_picker : ColorPicker

var _colors_index : PackedColorArray

var _child_item : Array[Control] = []
var _item_focus : int = 0

var tr_material := preload("../../resources/tile_transparant_material.tres")


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.project_file_changed.connect(func():
			update_palette()
			)
	PixelPen.color_picked.connect(func(palette_index):
			_item_focus = palette_index - 1
			)
	PixelPen.palette_changed.connect(update_palette)
	custom_minimum_size = Vector2(0, 0)


func _draw():
	if not _child_item.is_empty():
		var rect = Rect2(_child_item[_item_focus].position, _child_item[_item_focus].size)
		draw_rect(rect, Color.WHITE)
		rect = Rect2(_child_item[_item_focus].position + Vector2.ONE * 1, _child_item[_item_focus].size - Vector2.ONE * 2)
		draw_rect(rect, Color.BLACK)


func update_palette():
	var children = get_children()
	for child in children:
		child.queue_free()
	_child_item.clear()
	if PixelPen.current_project != null:
		_colors_index = PixelPen.current_project.palette.color_index
	

func _process(_delta):
	if not PixelPen.need_connection(get_window()):
		return
	if size != Vector2.ZERO and _child_item.is_empty() and PixelPen.current_project != null:
		var x_size = floorf(size.x / X_TOTAL)
		var item_size : Vector2 = Vector2.ONE * floorf(x_size - 4)
		custom_minimum_size = Vector2(0, x_size * (1 + floor(I_TOTAL / X_TOTAL)))
		
		tr_material.set_shader_parameter("tile_size", item_size.x / 4)

		var i : int = 0
		var y = 0
		while i < I_TOTAL:
			for x in range(X_TOTAL):
				var ch = _color_item(Vector2.ONE * x_size, item_size)
				ch.position = Vector2(x, y) * x_size
				if i < _colors_index.size() - 1:
					ch.get_node(COLOR_RECT_COLOR_NAME).color = _colors_index[i + 1]
				else:
					ch.get_node(COLOR_RECT_COLOR_NAME).color = PixelPen.current_project.palette.get_color_index_preset(i + 1)
					_colors_index.push_back(ch.get_node(COLOR_RECT_COLOR_NAME).color)
				add_child(ch)
				_child_item.push_back(ch)
				i += 1
				if i >= I_TOTAL:
					break
			y += 1
		color_picker.color = _child_item[_item_focus].get_node(COLOR_RECT_COLOR_NAME).color
		PixelPen.color_picked.emit(_item_focus + 1)
		queue_redraw()


func _color_item(wrapper_size : Vector2, item_size : Vector2):
	var wrapper = ColorRect.new()
	wrapper.tooltip_text = tooltip_text
	wrapper.size = wrapper_size
	wrapper.color = Color.TRANSPARENT
	
	var tr = ColorRect.new()
	tr.set_anchors_preset(Control.PRESET_CENTER)
	tr.size = item_size
	tr.position = item_size * -0.5
	tr.mouse_filter = Control.MOUSE_FILTER_PASS
	tr.material = tr_material
	wrapper.add_child(tr)
	
	var ar = ColorRect.new()
	ar.name = COLOR_RECT_COLOR_NAME
	ar.set_anchors_preset(Control.PRESET_CENTER)
	ar.size = item_size
	ar.position = item_size * -0.5
	ar.mouse_filter = Control.MOUSE_FILTER_PASS
	wrapper.add_child(ar)
	
	wrapper.gui_input.connect(func(event : InputEvent):
			if event and event is InputEventMouseButton:
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					if Input.is_key_pressed(KEY_SHIFT):
						(PixelPen.current_project as PixelPenProject).create_undo_layers("switch color", func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
						var index_a = _item_focus + 1
						_item_focus = _child_item.find(wrapper)
						var index_b = _item_focus + 1

						var i_n = (PixelPen.current_project as PixelPenProject).index_image.size()
						for i in range(i_n):
							(PixelPen.current_project as PixelPenProject).index_image[i].switch_color(index_a, index_b)
						
						(PixelPen.current_project as PixelPenProject).create_redo_layers(func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
						
						PixelPen.project_saved.emit(false)
						PixelPen.palette_changed.emit()
					elif Input.is_key_pressed(KEY_ALT):
						(PixelPen.current_project as PixelPenProject).create_undo_palette("copy palette", func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
							
						var copied_color = _colors_index[_item_focus + 1]
						_item_focus = _child_item.find(wrapper)
						_colors_index[_item_focus + 1] = copied_color
						
						(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
							
						PixelPen.project_saved.emit(false)
						PixelPen.palette_changed.emit()
					else:
						_item_focus = _child_item.find(wrapper)
						color_picker.color = ar.color
						PixelPen.color_picked.emit(_item_focus + 1)
						queue_redraw()
				elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
					if Input.is_key_pressed(KEY_SHIFT):
						(PixelPen.current_project as PixelPenProject).create_undo_palette("copy palette", func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
								
						_item_focus = _child_item.find(wrapper)
						_colors_index[_item_focus + 1].a = 1.0
						
						(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
							
						PixelPen.project_saved.emit(false)
						PixelPen.palette_changed.emit()
					else:
						(PixelPen.current_project as PixelPenProject).create_undo_layer_and_palette("switch palette position", func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
						
						var index_a = _item_focus + 1
						_item_focus = _child_item.find(wrapper)
						var index_b = _item_focus + 1
						
						var _cache_a = _colors_index[index_a]
						_colors_index[index_a] = _colors_index[index_b]
						_colors_index[index_b] = _cache_a
						
						var i_n = (PixelPen.current_project as PixelPenProject).index_image.size()
						for i in range(i_n):
							(PixelPen.current_project as PixelPenProject).index_image[i].switch_palette(index_a, index_b)
						
						(PixelPen.current_project as PixelPenProject).create_redo_layer_and_palette(func():
								PixelPen.project_saved.emit(false)
								PixelPen.palette_changed.emit()
								)
							
						PixelPen.project_saved.emit(false)
						PixelPen.palette_changed.emit()
			)
	return wrapper


func _on_color_picker_color_changed(color):
	if not PixelPen.project_file_changed.get_connections():
		return
	if PixelPen.current_project == null:
		return
	_child_item[_item_focus].get_node(COLOR_RECT_COLOR_NAME).color = color
	
	_colors_index[_item_focus + 1] = color
	
	PixelPen.color_picked.emit(_item_focus + 1)
	PixelPen.project_saved.emit(false)
