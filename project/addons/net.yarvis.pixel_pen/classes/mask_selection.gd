class_name MaskSelection
extends RefCounted


static func create_empty(size : Vector2i, margin : Vector2i = Vector2i.ONE )-> Image:
	return Image.create(size.x + margin.x * 2, size.y + margin.y * 2, false, Image.FORMAT_R8)


static func create_image(polygon : PackedVector2Array, size : Vector2i, margin : Vector2i = Vector2i.ONE) -> Image:
	var image := Image.create(size.x + margin.x * 2, size.y + margin.y * 2, false, Image.FORMAT_R8)
	for x in range(size.x):
		for y in range(size.y):
			var c : Color = Color8(0,0,0,0)
			if Geometry2D.is_point_in_polygon(Vector2(x, y) + Vector2(0.5, 0.5), polygon):
				c = Color8(255,0,0)
			image.set_pixel(x + margin.x, y + margin.y, c)
	return image


static func get_image_no_margin(image : Image, margin : Vector2i = Vector2i.ONE):
	return image.get_region(Rect2i(margin, image.get_size() - margin * 2))


static func union_image(image_a : Image, image_b : Image)-> Image:
	var rect = image_b.get_used_rect()
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			if image_b.get_pixel(x + rect.position.x, y + rect.position.y).r8 != 0:
				image_a.set_pixel(x + rect.position.x, y + rect.position.y, Color8(255,0,0))
	return image_a


static func difference_image(image_a : Image, image_b : Image)-> Image:
	var rect = image_b.get_used_rect()
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			if image_b.get_pixel(x + rect.position.x, y + rect.position.y).r8 != 0:
				image_a.set_pixel(x + rect.position.x, y + rect.position.y, Color8(0,0,0,0))
	return image_a


static func intersection_image(image_a : Image, image_b : Image)-> Image:
	var new_image = Image.create(image_a.get_size().x, image_a.get_size().y, false, Image.FORMAT_R8)
	var rect = image_b.get_used_rect()
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			var yes_b : bool = image_b.get_pixel(x + rect.position.x, y + rect.position.y).r8 != 0
			if yes_b and image_a.get_pixel(x + rect.position.x, y + rect.position.y).r8 != 0:
				new_image.set_pixel(x + rect.position.x, y + rect.position.y, Color8(255,0,0))
	return new_image


static func offset_image(image : Image, offset : Vector2i, new_size : Vector2i, margin : Vector2i = Vector2i.ONE) -> Image:
	var new_image = Image.create(new_size.x + margin.x * 2, new_size.y + margin.y * 2, false, Image.FORMAT_R8)
	for x in range(margin.x, new_image.get_width() - margin.x):
		for y in range(margin.y, new_image.get_height() - margin.y):
			var src_x = x - offset.x
			var src_y = y - offset.y
			var inside_src_image_bound = src_x >= margin.x and src_x < image.get_width() - margin.x
			inside_src_image_bound = inside_src_image_bound and src_y >= margin.y and src_y < image.get_height() - margin.y
			if inside_src_image_bound:
				var index_image = image.get_pixel(src_x, src_y).r8
				if index_image != 0:
					new_image.set_pixel(x, y, Color8(index_image, 0, 0))
	return new_image


static func get_mask_used_rect(mask : Image)-> Rect2i:
	return PixelPen.utils.get_mask_used_rect(mask);
