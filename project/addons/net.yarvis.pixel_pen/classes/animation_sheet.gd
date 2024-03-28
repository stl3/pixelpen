@tool
class_name AnimationSheet
extends Resource

@export var uuid : String
@export var fps : float
@export var grid_size : Vector2i
@export var region : Rect2i


static func create() -> AnimationSheet:
	var anim = AnimationSheet.new()
	anim.uuid = PixelPen.uuid.v4()
	anim.fps = 12
	anim.grid_size = Vector2i(PixelPen.current_project.checker_size, PixelPen.current_project.checker_size)
	anim.region = Rect2i(Vector2i.ZERO, (PixelPen.current_project as PixelPenProject).canvas_size)
	return anim
