@tool
class_name IndexedPalette
extends Resource


const INDEX_COLOR_SIZE = 256

@export var color_index : PackedColorArray = [Color.TRANSPARENT]


func save_image(path : String):
	var solid_color : PackedColorArray = []
	for color in color_index:
		if color.a > 0:
			solid_color.push_back(color)
	var width : int = 1
	var height : int = solid_color.size()
	var image : Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for n in range(solid_color.size()):
		image.set_pixel(0, n, solid_color[n])
	image.resize(width * 16, height * 16, Image.INTERPOLATE_NEAREST)
	var ext = path.get_extension()
	if ext == "png":
		image.save_png(path)
	elif ext == "jpg" or ext == "jpeg":
		image.save_jpg(path)
	elif ext == "webp":
		image.save_webp(path)
	else:
		image.save_png(path.get_basename() + ".png")


func load_image(path : String, merge : bool = false):
	if not merge or color_index.size() < INDEX_COLOR_SIZE:
		color_index.resize(INDEX_COLOR_SIZE)
	if not merge:
		color_index.fill(Color.TRANSPARENT)
	var image : Image = Image.load_from_file(path)
	var i : int = 1 # keep index 0 as TRANSPARENT
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if merge:
				while color_index[i].a > 0:
					i += 1 
					if i >= color_index.size():
						return
			var color : Color = image.get_pixel(x, y)
			if color_index.find(color) == -1:
				color_index[i] = color
				i += 1
				if i >= color_index.size():
					return


func set_color_index_preset():
	color_index.resize(INDEX_COLOR_SIZE)
	color_index.fill(Color.TRANSPARENT)
	for i in range(2):
		color_index[i] = get_color_index_preset(i)


func get_color_index_preset(i : int) -> Color:
	if i == 0:
		return Color.TRANSPARENT
	if i == 1:
		return Color.BLACK
	if i == 2:
		return Color.WHITE
	if i < 11:
		return Color.from_hsv((i - 3) / 8.0, 0.7, 0.9)
	return Color.TRANSPARENT


func get_color_index_texture():
	var image = Image.create(color_index.size(), 1, false, Image.FORMAT_RGBAF)
	for i in range(color_index.size()):
		image.set_pixel(i, 0, color_index[i])
	return ImageTexture.create_from_image(image)


func get_sorted_palette() -> PackedColorArray:
	
	var sort = func(a : Color, b : Color)-> bool:
		var step : float = 8
		var ah := int(a.h * step)
		var al := int(a.get_luminance() * step)
		var av := int(a.v * step)
		
		if ah % 2 == 1:
			al = step - al
			av = step - av
		
		var bh := int(b.h * step)
		var bl := int(b.get_luminance() * step)
		var bv := int(b.v * step)
		
		if bh % 2 == 1:
			bl = step - bl
			bv = step - bv
		
		if ah == bh:
			if al == bl:
				return av > bv
			return al > bl
		return ah > bh
	
	var new_palette : Array[Color] = []
	for c in range(1, color_index.size()):
		if color_index[c].a > 0:
			new_palette.push_back(color_index[c])
	new_palette.sort_custom(sort)
	var new_palette_packed : PackedColorArray = []
	new_palette_packed.resize(INDEX_COLOR_SIZE)
	new_palette_packed.fill(Color.TRANSPARENT)
	for i in range(new_palette.size()):
		if i + 1 < new_palette_packed.size():
			new_palette_packed[i + 1] = new_palette[i]
	return new_palette_packed
