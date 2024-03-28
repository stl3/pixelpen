@tool
extends TextureRect


func _draw():
	draw_rect(Rect2i(Vector2.ZERO, size), Color.MAGENTA, false)


func _process(_delta):
	queue_redraw()
