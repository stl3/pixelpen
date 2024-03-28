@tool
extends Resource
class_name UserConfig


const PATH := "user://pixelpen_user_config.res"

@export var brush : Array[Image]


static func load_data():
	if ResourceLoader.exists(PATH):
		var res = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		return res
	return UserConfig.new()


func save():
	ResourceSaver.save(self, PATH)


func make_brush_from_project() -> bool:
	if PixelPen.current_project == null:
		return false
	var img : Image = (PixelPen.current_project as PixelPenProject).get_image()
	var size : Vector2i = img.get_size()
	var brush_image : Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for x in range(size.x):
		for y in range(size.y):
			brush_image.set_pixel(x, y, Color8(255, 255, 255, img.get_pixel(x, y).a8))
	brush.push_back(brush_image)
	save()
	return true


func delete_brush(index : int):
	if index < brush.size() and index >= 0:
		brush.remove_at(index)
		save()
