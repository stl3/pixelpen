@tool
extends Window


static var last_position : Vector2i

@export var node : TextureRect
@export var aspect_ratio : AspectRatioContainer
@export var shader_node : ColorRect
@export var prop_box : Control
@export var animation_id_menu : MenuButton
@export var fps_spinner : SpinBox
@export var grid_size_x : SpinBox
@export var grid_size_y : SpinBox
@export var region_position_x : SpinBox
@export var region_position_y : SpinBox
@export var region_size_x : SpinBox
@export var region_size_y : SpinBox

var fps : float:
	get:
		return fps_spinner.get_line_edit().text as float
var grid_size : Vector2i:
	get:
		return Vector2i(grid_size_x.get_line_edit().text as int, grid_size_y.get_line_edit().text as int)
var region : Rect2i:
	get:
		return Rect2i(
			Vector2i(region_position_x.get_line_edit().text as int, region_position_y.get_line_edit().text as int), 
			Vector2i(region_size_x.get_line_edit().text as int, region_size_y.get_line_edit().text as int))

var frames : Array[Image] = []
var anim_sheet : AnimationSheet

var _last_time : float
var _frames_current_frame : int


func init():
	fps_spinner.value_changed.connect(func (v):
			anim_sheet.fps = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	grid_size_x.value_changed.connect(func (v):
			anim_sheet.grid_size.x = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	grid_size_y.value_changed.connect(func (v):
			anim_sheet.grid_size.y = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	region_position_x.value_changed.connect(func (v):
			anim_sheet.region.position.x = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	region_position_y.value_changed.connect(func (v):
			anim_sheet.region.position.y = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	region_size_x.value_changed.connect(func (v):
			anim_sheet.region.size.x = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	region_size_y.value_changed.connect(func (v):
			anim_sheet.region.size.y = v
			create_animation()
			(PixelPen.current_project as PixelPenProject).property_changed.emit(false)
			)
	PixelPen.project_file_changed.connect(func():
			if PixelPen.current_project == null:
				hide()
				queue_free()
			)
	(PixelPen.current_project as PixelPenProject).property_changed.connect(func(state):
			create_animation()
			)
	var sheets : Array[AnimationSheet] = (PixelPen.current_project as PixelPenProject).animation_sheets
	if sheets.is_empty():
		sheets.push_back(AnimationSheet.create())
	anim_sheet = sheets[0]
	animation_id_menu.text = anim_sheet.uuid
	var popup : PopupMenu = animation_id_menu.get_popup()
	popup.clear()
	for i in range(sheets.size()):
		popup.add_item(sheets[i].uuid, i)
	popup.id_pressed.connect(func (id):
			anim_sheet = sheets[id]
			update_field()
			create_animation()
			)
	update_field()
	create_animation()


func update_field():
	fps_spinner.get_line_edit().text = str(anim_sheet.fps)
	grid_size_x.get_line_edit().text = str(anim_sheet.grid_size.x)
	grid_size_y.get_line_edit().text = str(anim_sheet.grid_size.y)
	region_position_x.get_line_edit().text = str(anim_sheet.region.position.x)
	region_position_y.get_line_edit().text = str(anim_sheet.region.position.y)
	region_size_x.get_line_edit().text = str(anim_sheet.region.size.x)
	region_size_y.get_line_edit().text = str(anim_sheet.region.size.y)


func _on_spinner_changed(_ignore):
	create_animation()


func create_animation():
	if PixelPen.current_project == null:
		return
	aspect_ratio.ratio = grid_size.x / grid_size.y
	size.x = 320
	size.y = prop_box.size.y + size.x * grid_size.y / grid_size.x
	var image = PixelPen.current_project.get_image()
	var max_i = (region.size / grid_size).x * (region.size / grid_size).y
	frames.clear()
	for i in range(max_i):
		frames.push_back(create_frame(i, image))


func create_frame(i : int, image : Image):
	var grid_region : Rect2i = Rect2i(Vector2i.ZERO, grid_size)
	var siz : Vector2i = region.size / grid_size
	grid_region.position.x = i % siz.x
	grid_region.position.y = (i - grid_region.position.x) / siz.x
	grid_region.position *= grid_size
	grid_region.position += region.position
	return image.get_region(grid_region)


func popup_in_last_position():
	if last_position != Vector2i.ZERO:
		popup(Rect2i(last_position, Vector2i(320, 520)))
	else:
		popup_centered()


func show_frame(i : int):
	if node.texture == null or (node.texture.get_size() as Vector2i) != frames[i].get_size():
		node.texture = ImageTexture.create_from_image(frames[i])
	else:
		node.texture.update(frames[i])


func _physics_process(delta):
	if frames.size() == 0:
		return
	
	_last_time += delta
	if _last_time >= 1 / fps:
		_last_time = delta
		
		show_frame(_frames_current_frame)
		_frames_current_frame += 1
		if _frames_current_frame >= frames.size():
			_frames_current_frame = 0
	
	shader_node.material.set_shader_parameter("origin", node.global_position)
	shader_node.material.set_shader_parameter("tile_size", node.size.y / grid_size.y)


func _on_close_requested():
	last_position = position
	hide()
	queue_free()
