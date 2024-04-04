@tool
## Resource or Project FILE for every PixelPenProject
class_name PixelPenProject
extends Resource


@export var project_name : String
@export var file_path : String
@export var last_export_file_path : String
@export var canvas_size : Vector2i
@export var palette : IndexedPalette
@export var index_image : Array[IndexedColorImage]
@export var animation_sheets : Array[AnimationSheet]
@export var checker_size : int:
	get:
		return max(checker_size, 1)
## Used by internal for auto name layer
@export var layer_index_counter : int
@export var active_layer_uuid : String
@export var use_sample : bool = false
@export var _sample_offset : Vector2i
@export var _cache_canvs_size : Vector2i
@export var _cache_index_image : Array[IndexedColorImage]

var active_layer : IndexedColorImage:
	get:
		return get_index_image(active_layer_uuid)
var is_saved : bool = false

var undo_redo : UndoRedoManager

var cache_copied_colormap : IndexedColorImage
var cache_thumbnail : Image

var _cache_undo_redo : UndoRedoManager

enum ProjectMode{
	BASE = 0,
	SAMPLE = 1
}


func initialized(p_size : Vector2i, p_name : String = "Untitled", p_checker_size : int = 16, p_file_path : String = "", one_layer : bool = true):
	layer_index_counter = 0
	project_name = p_name
	canvas_size = p_size
	checker_size = p_checker_size
	palette = IndexedPalette.new()
	palette.set_color_index_preset()
	index_image.clear()
	animation_sheets.clear()
	if one_layer:
		add_layer()
		active_layer_uuid = index_image[0].layer_uuid


func set_mode(mode : ProjectMode, mask : Image = null):
	if mode == ProjectMode.BASE and use_sample:
		for idx in range(_cache_index_image.size()):
			var i : int = get_image_index(_cache_index_image[idx].layer_uuid)
			if i != -1:
				_cache_index_image[i].colormap.blit_rect(index_image[i].colormap, Rect2i(Vector2i.ZERO, index_image[i].colormap.get_size()), _sample_offset)
		use_sample = false
		canvas_size = _cache_canvs_size
		index_image = _cache_index_image
		undo_redo = _cache_undo_redo
	elif mode == ProjectMode.SAMPLE and mask != null and not use_sample:
		use_sample = true
		_cache_canvs_size = canvas_size
		_cache_index_image = get_index_image_duplicate()
		_cache_undo_redo = undo_redo
		var region : Rect2i = PixelPen.utils.get_mask_used_rect(mask)
		canvas_size = region.size
		_sample_offset = region.position
		for i in range(index_image.size()):
			var new_layer : IndexedColorImage = index_image[i].get_duplicate()
			new_layer.size = canvas_size
			new_layer.colormap = index_image[i].colormap.get_region(region)
			index_image[i] = new_layer
		undo_redo = UndoRedoManager.new()
	PixelPen.edit_mode_changed.emit(mode)


func resize_canvas(new_size : Vector2i, anchor : PixelPen.ResizeAnchor):
	canvas_size = new_size
	var size = index_image.size()
	for i in range(size):
		index_image[i].resize(new_size, anchor)
	cache_copied_colormap = null


func undo():
	undo_redo.undo()


func redo():
	undo_redo.redo()


func create_undo_layer_and_palette(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(self, "index_image", get_index_image_duplicate())
	undo_redo.add_undo_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_layer_and_palette(callable : Callable):
	undo_redo.add_do_property(self, "index_image", get_index_image_duplicate())
	undo_redo.add_do_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_layers(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(self, "index_image", get_index_image_duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_layers(callable : Callable):
	undo_redo.add_do_property(self, "index_image", get_index_image_duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_palette(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_palette(callable : Callable):
	undo_redo.add_do_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_property(name : String, object : Object, property : String, value : Variant, callable : Callable, create : bool = false):
	if create: 
		undo_redo.create_action(name)
	undo_redo.add_undo_property(object, property, value)
	undo_redo.add_undo_method(callable)


func create_redo_property(object : Object, property : String, value : Variant, callable : Callable, commit : bool = false):
	undo_redo.add_do_property(object, property, value)
	undo_redo.add_do_method(callable)
	if commit:
		undo_redo.commit_action()


func get_index_image_duplicate() -> Array[IndexedColorImage]:
	var new_index_image = index_image.duplicate()
	for i in range(new_index_image.size()):
		new_index_image[i] = new_index_image[i].get_duplicate()
	return new_index_image


func set_image(new_index_image):
	index_image = new_index_image


func active_layer_is_valid():
	return get_image_index(active_layer_uuid) != -1


func add_layer(label : String = "", above_layer_uuid : String = "") -> String:
	var new_index_image = IndexedColorImage.new()
	if label == "":
		layer_index_counter += 1
		new_index_image.label = str("Layer " , layer_index_counter)
	else:
		new_index_image.label = label
	new_index_image.layer_uuid = PixelPen.uuid.v4()
	new_index_image.size = canvas_size
	var index = get_image_index(above_layer_uuid)
	if index == -1 or above_layer_uuid == "":
		index_image.insert(index_image.size(), new_index_image)
	else:
		index_image.insert(index + 1, new_index_image)
	return new_index_image.layer_uuid


func duplicate_layer(layer_uuid : String):
	var new_index_image : IndexedColorImage = get_index_image(layer_uuid)
	if new_index_image != null:
		new_index_image = new_index_image.get_duplicate()
	else:
		return
	layer_index_counter += 1
	new_index_image.label = str(new_index_image.label , " Duplicate", layer_index_counter)
	new_index_image.layer_uuid = PixelPen.uuid.v4()
	var index = get_image_index(layer_uuid)
	if index == -1:
		index_image.insert(index_image.size(), new_index_image)
	else:
		index_image.insert(index + 1, new_index_image)


func paste_copied_layer(above_layer_uuid : String = ""):
	var new_index_image : IndexedColorImage = cache_copied_colormap
	if new_index_image != null:
		new_index_image = new_index_image.get_duplicate()
	else:
		return
	layer_index_counter += 1
	new_index_image.label = str(new_index_image.label , " Copy", layer_index_counter)
	new_index_image.layer_uuid = PixelPen.uuid.v4()
	var index = get_image_index(above_layer_uuid)
	if index == -1:
		index_image.insert(index_image.size(), new_index_image)
	else:
		index_image.insert(index + 1, new_index_image)
	active_layer_uuid = new_index_image.layer_uuid


func delete_layer(layer_uuid : String):
	var index = get_image_index(layer_uuid)
	if index != -1:
		index_image.remove_at(index)
	if index_image.size() == 0:
		layer_index_counter = 0


func sort_palette():
	var new_palette : PackedColorArray = palette.get_sorted_palette()
	var i_n = index_image.size()
	for j in range(i_n):
		PixelPen.utils.swap_palette(palette.color_index, new_palette, index_image[j].colormap)
	palette.color_index = new_palette


func delete_unused_color_palette():
	var i_size : int = index_image.size()
	var new_palette : PackedColorArray = []
	for i in range(i_size):
		for x in range(index_image[i].colormap.get_width()):
			for y in range(index_image[i].colormap.get_height()):
				var idx : int = index_image[i].colormap.get_pixel(x, y).r8
				var color : Color = palette.color_index[idx]
				if color not in new_palette:
					new_palette.push_back(color)
	
	var new_palette_final : PackedColorArray = palette.color_index.duplicate()
	var i = 0
	while i < new_palette_final.size() and i < palette.INDEX_COLOR_SIZE:
		if new_palette_final[i] not in new_palette and new_palette_final[i] != Color.TRANSPARENT:
			new_palette_final.remove_at(i)
			new_palette_final.push_back(Color.TRANSPARENT)
		else:
			i += 1
	
	var i_n = index_image.size()
	for j in range(i_n):
		PixelPen.utils.swap_palette(palette.color_index, new_palette_final, index_image[j].colormap)
	
	palette.color_index = new_palette_final


func delete_color(palette_index : int):
	var new_palette : PackedColorArray = palette.color_index.duplicate()
	new_palette.remove_at(palette_index)
	new_palette.push_back(Color.TRANSPARENT)
	var i_n = index_image.size()
	for j in range(i_n):
		PixelPen.utils.swap_palette(palette.color_index, new_palette, index_image[j].colormap)
	palette.color_index = new_palette


func get_image_index(layer_uuid : String) -> int:
	var active_layer_index : int  = -1
	for i in range(index_image.size()):
		if (index_image[i].layer_uuid as StringName) == (layer_uuid as StringName):
			active_layer_index = i
			break
	return active_layer_index


func get_index_image(layer_uuid : String) -> IndexedColorImage:
	var active_layer_index : int  = -1
	for i in range(index_image.size()):
		if (index_image[i].layer_uuid as StringName) == (layer_uuid as StringName):
			active_layer_index = i
			break
	if active_layer_index == -1:
		return null
	return index_image[active_layer_index]


func get_layer_image(layer_uuid : String) -> Image:
	var image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	var color_map : Image = get_index_image(layer_uuid).colormap
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			image.set_pixel(x, y, palette.color_index[color_map.get_pixel(x, y).r8])
	
	return image


func get_image() -> Image:
	var canvas_image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	for index in range(index_image.size()):
		if not index_image[index].visible:
			continue
		var image = PixelPen.utils.get_image(palette.color_index, index_image[index].colormap, false)
		var rect  = image.get_used_rect()
		canvas_image.blend_rect(image, rect, rect.position)
	cache_thumbnail = canvas_image
	return canvas_image


func import_file(path : String) -> String:
	var image : Image = Image.load_from_file(path)
	image.convert(Image.FORMAT_RGBA8)
	var image_size : Vector2i = image.get_size()
	var layer_uuid = add_layer(path.get_file().get_basename(), active_layer_uuid)
	var index_image : IndexedColorImage = get_index_image(layer_uuid)
	palette.color_index = PixelPen.utils.import_image(index_image.colormap, image, palette.color_index)
	return layer_uuid


func import_image(image : Image, path : String) -> String:
	image.convert(Image.FORMAT_RGBA8)
	var image_size : Vector2i = image.get_size()
	var layer_uuid = add_layer(path.get_file().get_basename(), active_layer_uuid)
	var index_image : IndexedColorImage = get_index_image(layer_uuid)
	palette.color_index = PixelPen.utils.import_image(index_image.colormap, image, palette.color_index)
	return layer_uuid


func export_png_image(path : String) -> Error:
	var image : Image = get_image()
	image.convert(Image.FORMAT_RGBA8)
	last_export_file_path = path
	return image.save_png(path)


func export_jpg_image(path : String) -> Error:
	var image : Image = get_image()
	last_export_file_path = path
	return image.save_jpg(path, 1.0)


func export_webp_image(path : String) -> Error:
	var image : Image = get_image()
	image.convert(Image.FORMAT_RGBA8)
	last_export_file_path = path
	return image.save_webp(path)
