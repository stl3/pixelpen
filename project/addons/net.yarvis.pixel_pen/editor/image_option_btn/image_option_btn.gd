@tool
extends Control


signal selected(index)

@export var preview : TextureRect
@export var button : Button
@export var vbox : VBoxContainer
@export var popup_panel : PopupPanel

var _panel_size : Vector2
var _brush_index : int


func _ready():
	popup_panel.hide()


func select(index : int):
	if index < PixelPen.userconfig.brush.size() and index >= 0:
		preview.texture = ImageTexture.create_from_image(PixelPen.userconfig.brush[index])
		_brush_index = index
	else:
		preview.texture = null


func build_panel(images : Array[Image]):
	for child in vbox.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	var count : int = 0
	for i in range(images.size()):
		var texture_rect = TextureRect.new()
		texture_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(64, 64)
		texture_rect.texture = ImageTexture.create_from_image(images[i])
		texture_rect.gui_input.connect(func(event):
				input(vbox.get_children().find(texture_rect), event)
				)
		vbox.add_child(texture_rect)
		count += 1
	vbox.custom_minimum_size = Vector2(64, count * 64)
	_panel_size = vbox.custom_minimum_size + Vector2(32, 32)


func _on_button_pressed():
	popup_panel.popup(Rect2i(global_position + Vector2(size.x, size.x), _panel_size))


func input(index, event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			popup_panel.hide()
			selected.emit(index)
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			PixelPen.userconfig.delete_brush(index)
			popup_panel.hide()
			build_panel(PixelPen.userconfig.brush)
			if _brush_index > index:
				selected.emit(_brush_index - 1)
			else:
				selected.emit(_brush_index)
