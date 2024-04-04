@tool
extends AspectRatioContainer


@export var label : Label
@export var editor_canvas : Node2D
@export var texture_rect : TextureRect
@export var preview_container : Control
@export var canvas : Node2D

var thread = Thread.new()


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.project_file_changed.connect(func():
			if PixelPen.current_project != null:
				var sz = (PixelPen.current_project as PixelPenProject).canvas_size as Vector2
				ratio = sz.x / sz.y
				PixelPen.layer_items_changed.connect(func ():
						if thread.is_started():
							thread.wait_to_finish()
						if preview_container.visible:
							thread.start(_on_update_preview)
						elif canvas.show_tile:
							(PixelPen.current_project as PixelPenProject).get_image()
							PixelPen.thumbnail_changed.emit()
						)
				if thread.is_started():
					thread.wait_to_finish()
				thread.start(_on_update_preview)
			)


func _on_update_preview():
	if PixelPen.current_project == null :
		return
	var texture = ImageTexture.create_from_image((PixelPen.current_project as PixelPenProject).get_image())
	PixelPen.call_deferred("emit_signal", "thumbnail_changed")
	texture_rect.call_deferred("set_texture", texture)


func _exit_tree():
	if thread.is_started():
		thread.wait_to_finish()
