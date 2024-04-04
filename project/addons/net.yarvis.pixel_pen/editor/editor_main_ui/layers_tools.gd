@tool
extends Control


const LayerProperties := preload("../layer_properties.tscn")
const MoveTool := preload("../editor_canvas/move_tool.gd")

@export var popup_menu : PopupMenu
@export var canvas_node : Node2D
@export var add_layer : TextureButton
@export var delete_layer : TextureButton


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	var disable_btn = func():
			var is_disable = PixelPen.current_project == null
			for child in get_children():
				if child is TextureButton:
					child.disabled = is_disable
	PixelPen.project_file_changed.connect(disable_btn)
	disable_btn.call()
	
	PixelPen.request_layer_properties.connect(_on_layer_properties)
	PixelPen.edit_mode_changed.connect(func(mode: PixelPenProject.ProjectMode):
			add_layer.visible = mode == PixelPenProject.ProjectMode.BASE
			delete_layer.visible = mode == PixelPenProject.ProjectMode.BASE
			)


func _on_layer_properties(layer_uuid : String) -> ConfirmationDialog:
	var lp = LayerProperties.instantiate()
	lp.layer_uuid = layer_uuid
	add_child(lp)
	lp.popup_in_last_position()
	return lp


func _on_add_pressed():
	var window = _on_layer_properties("")
	window.confirmed.connect(func():
			(PixelPen.current_project as PixelPenProject).create_undo_layers("Add layer", func ():
					PixelPen.layer_items_changed.emit()
					PixelPen.project_saved.emit(false)
					)
			(PixelPen.current_project as PixelPenProject).add_layer(window.layer_name, PixelPen.current_project.active_layer_uuid)
			(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
					PixelPen.layer_items_changed.emit()
					PixelPen.project_saved.emit(false)
					)
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)


func _on_duplicate_layer():
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Duplicate layer", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	(PixelPen.current_project as PixelPenProject).duplicate_layer(PixelPen.current_project.active_layer_uuid)
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_copy_layer():
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap = (PixelPen.current_project as PixelPenProject).active_layer.get_duplicate()


func _on_cut_layer():
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap = (PixelPen.current_project as PixelPenProject).active_layer.get_duplicate()
	_on_trash_pressed()


func _on_duplicate_selection():
	if canvas_node.selection_tool_hint.texture == null:
		return
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
		
	var mask_selection = MaskSelection.get_image_no_margin(canvas_node.selection_tool_hint.texture.get_image())
	var colormap_image : Image = index_image.get_color_map_with_mask(mask_selection)
	
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap = index_image.get_duplicate()
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap.colormap = colormap_image.duplicate()
	_on_paste()


func _on_copy_selection():
	if canvas_node.selection_tool_hint.texture == null:
		return
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
		
	var mask_selection = MaskSelection.get_image_no_margin(canvas_node.selection_tool_hint.texture.get_image())
	var colormap_image : Image = index_image.get_color_map_with_mask(mask_selection)
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap = index_image.get_duplicate()
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap.colormap = colormap_image.duplicate()


func _on_cut_selection():
	if canvas_node.selection_tool_hint.texture == null:
		return
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
		
	var mask_selection = MaskSelection.get_image_no_margin(canvas_node.selection_tool_hint.texture.get_image())
	var colormap_image : Image = index_image.get_color_map_with_mask(mask_selection)
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap = index_image.get_duplicate()
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap.colormap = colormap_image.duplicate()
	
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Cut selection", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	index_image.empty_index_on_color_map(mask_selection)
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_paste():
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Paste layer", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	(PixelPen.current_project as PixelPenProject).paste_copied_layer(PixelPen.current_project.active_layer_uuid)
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)
	(PixelPen.current_project as PixelPenProject).cache_copied_colormap = null


func _on_merge_down():
	var active_layer_index : int = PixelPen.current_project.get_image_index(PixelPen.current_project.active_layer_uuid)
	if active_layer_index == -1:
		return
		
	var below_layer_index : int = active_layer_index - 1
	if below_layer_index <= -1:
		return
	
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Merge down", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	
	var active_img = (PixelPen.current_project as PixelPenProject).active_layer.get_color_map_with_mask()
	(PixelPen.current_project as PixelPenProject).index_image[below_layer_index].blit_color_map(active_img, null, Vector2i.ZERO)
	(PixelPen.current_project as PixelPenProject).delete_layer(PixelPen.current_project.active_layer_uuid)
	PixelPen.current_project.active_layer_uuid = (PixelPen.current_project as PixelPenProject).index_image[below_layer_index].layer_uuid
	(PixelPen.current_project as PixelPenProject).index_image[below_layer_index].visible = true
	
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_merge_visible():
	if (PixelPen.current_project as PixelPenProject).index_image.size() <= 1:
		return
	
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Merge visible", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	var j = 0
	for i in range((PixelPen.current_project as PixelPenProject).index_image.size() -1, -1, -1):
		if (PixelPen.current_project as PixelPenProject).index_image[i].visible:
			j = i
			break
	
	var new_arr : Array[IndexedColorImage] = []
	var prev_img = (PixelPen.current_project as PixelPenProject).index_image[j].get_color_map_with_mask()
	var last_index = j
	for i in range((PixelPen.current_project as PixelPenProject).index_image.size() -1, -1, -1):
		if j != i and (PixelPen.current_project as PixelPenProject).index_image[i].visible:
			(PixelPen.current_project as PixelPenProject).index_image[i].blit_color_map(prev_img, null, Vector2i.ZERO)
			prev_img = (PixelPen.current_project as PixelPenProject).index_image[i].get_color_map_with_mask()
			last_index = i
		if not (PixelPen.current_project as PixelPenProject).index_image[i].visible:
			new_arr.push_back((PixelPen.current_project as PixelPenProject).index_image[i])
	new_arr.push_back((PixelPen.current_project as PixelPenProject).index_image[last_index])
	(PixelPen.current_project as PixelPenProject).index_image = new_arr
	
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_merge_all():
	if (PixelPen.current_project as PixelPenProject).index_image.size() <= 1:
		return
	
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Merge all", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	var j = 0
	for i in range((PixelPen.current_project as PixelPenProject).index_image.size() -1, -1, -1):
		if (PixelPen.current_project as PixelPenProject).index_image[i].visible:
			j = i
			break
	
	var prev_img = (PixelPen.current_project as PixelPenProject).index_image[j].get_color_map_with_mask()
	var last_index = j
	for i in range(j, -1, -1):
		if (PixelPen.current_project as PixelPenProject).index_image[i].visible:
			(PixelPen.current_project as PixelPenProject).index_image[i].blit_color_map(prev_img, null, Vector2i.ZERO)
			prev_img = (PixelPen.current_project as PixelPenProject).index_image[i].get_color_map_with_mask()
			last_index = i
	(PixelPen.current_project as PixelPenProject).index_image = [(PixelPen.current_project as PixelPenProject).index_image[last_index]]
	
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_hide_all():
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Remove layer", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	for img in (PixelPen.current_project as PixelPenProject).index_image:
		img.visible = false
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_show_all():
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Remove layer", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	for img in (PixelPen.current_project as PixelPenProject).index_image:
		img.visible = true
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_apply_prev_move_transform():
	var index_image : IndexedColorImage = (PixelPen.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
	
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Apply prev move transform", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	
	var move_cache_image_map = index_image.get_color_map_with_mask(MoveTool.cache_move_transform_mask)
	index_image.empty_index_on_color_map(MoveTool.cache_move_transform_mask)
	index_image.blit_color_map(move_cache_image_map, MoveTool.cache_move_transform_mask, MoveTool.cache_move_transform)
	
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_folder_pressed():
	pass


func _on_trash_pressed():
	(PixelPen.current_project as PixelPenProject).create_undo_layers("Remove layer", func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	PixelPen.current_project.delete_layer(PixelPen.current_project.active_layer_uuid)
	(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
			)
	
	PixelPen.layer_items_changed.emit()
	PixelPen.project_saved.emit(false)


func _on_menu_pressed():
	popup_menu.show_popup()
