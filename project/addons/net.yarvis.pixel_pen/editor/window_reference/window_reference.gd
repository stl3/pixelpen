@tool
extends Window

@export var texture : TextureRect


func load_texture(file : String):
	var image = Image.load_from_file(file)
	title = file.get_file().get_basename()
	texture.texture = ImageTexture.create_from_image(image)
	size.x = 520
	size.y = 520 * image.get_size().y / image.get_size().x


func _on_close_requested():
	hide()
	queue_free()
