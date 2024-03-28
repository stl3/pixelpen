@tool
extends PopupMenu

const MoveTool := preload("../editor_canvas/move_tool.gd")


enum ItemID{
	ADD_LAYER = 0,
	DELETE_LAYER,
	DUPLICATE_LAYER,
	COPY_LAYER,
	CUT_LAYER,
	DUPLICATE_SELECTION,
	COPY_SELECTION,
	CUT_SELECTION,
	PASTE,
	RENAME_LAYER,
	MERGE_DOWN,
	MERGE_VISIBLE,
	MERGE_ALL,
	SHOW_ALL_LAYER,
	HIDE_ALL_LAYER,
	APPLY_PREVIOUS_MOVE_TRANSFORM
}


@export var layers_tool : Control
@export var canvas_node : Node2D


func _init():
	clear(true)
	add_item("Add layer...", ItemID.ADD_LAYER)
	add_item("Delete layer", ItemID.DELETE_LAYER)
	add_separator()
	add_item("Duplicate layer", ItemID.DUPLICATE_LAYER)
	add_item("Copy layer", ItemID.COPY_LAYER)
	add_item("Cut layer", ItemID.CUT_LAYER)
	add_separator()
	add_item("Duplicate selection", ItemID.DUPLICATE_SELECTION)
	add_separator()
	add_item("Paste to new layer", ItemID.PASTE)
	add_separator()
	add_item("Rename layer...", ItemID.RENAME_LAYER)
	add_separator()
	add_item("Merge down", ItemID.MERGE_DOWN)
	add_item("Merge visible", ItemID.MERGE_VISIBLE)
	add_item("Merge all", ItemID.MERGE_ALL)
	add_separator()
	add_item("Show all layers", ItemID.SHOW_ALL_LAYER)
	add_item("Hide all layers", ItemID.HIDE_ALL_LAYER)
	add_separator()
	add_item("Apply previous move transform", ItemID.APPLY_PREVIOUS_MOVE_TRANSFORM)


func show_popup():
	if PixelPen.current_project == null:
		return
	var disable = (PixelPen.current_project as PixelPenProject).active_layer == null
	var selection = canvas_node.selection_tool_hint.texture == null
	var edit_mode_sample : bool = PixelPen.current_project.use_sample
	
	set_item_disabled(get_item_index(ItemID.ADD_LAYER), edit_mode_sample)
	
	set_item_disabled(get_item_index(ItemID.DELETE_LAYER), disable or edit_mode_sample)
	set_item_disabled(get_item_index(ItemID.DUPLICATE_LAYER), disable or edit_mode_sample)
	
	set_item_disabled(get_item_index(ItemID.COPY_LAYER), disable or edit_mode_sample)
	set_item_disabled(get_item_index(ItemID.CUT_LAYER), disable or edit_mode_sample)
	
	set_item_disabled(get_item_index(ItemID.DUPLICATE_SELECTION), disable or selection or edit_mode_sample)
	
	set_item_disabled(get_item_index(ItemID.PASTE), (PixelPen.current_project as PixelPenProject).cache_copied_colormap == null or edit_mode_sample)
	
	set_item_disabled(get_item_index(ItemID.RENAME_LAYER), disable)
	
	set_item_disabled(get_item_index(ItemID.MERGE_DOWN), disable or edit_mode_sample)
	set_item_disabled(get_item_index(ItemID.MERGE_VISIBLE), edit_mode_sample)
	set_item_disabled(get_item_index(ItemID.MERGE_ALL), edit_mode_sample)
	
	set_item_disabled(get_item_index(ItemID.APPLY_PREVIOUS_MOVE_TRANSFORM), MoveTool.cache_move_transform == Vector2i.ZERO)
	
	position =  (get_parent().get_window().position as Vector2) + get_parent().global_position - (size as Vector2)
	show()


func _on_id_pressed(id : int):
	if PixelPen.current_project != null:
		match id as ItemID:
			ItemID.ADD_LAYER:
				layers_tool._on_add_pressed()
			ItemID.DUPLICATE_LAYER:
				layers_tool._on_duplicate_layer()
			ItemID.COPY_LAYER:
				layers_tool._on_copy_layer()
			ItemID.CUT_LAYER:
				layers_tool._on_cut_layer()
			ItemID.DELETE_LAYER:
				layers_tool._on_trash_pressed()
			ItemID.DUPLICATE_SELECTION:
				layers_tool._on_duplicate_selection()
			ItemID.PASTE:
				layers_tool._on_paste()
			ItemID.RENAME_LAYER:
				var uuid = (PixelPen.current_project as PixelPenProject).active_layer
				if uuid != null:
					layers_tool._on_layer_properties(uuid.layer_uuid)
			ItemID.MERGE_DOWN:
				layers_tool._on_merge_down()
			ItemID.MERGE_VISIBLE:
				layers_tool._on_merge_visible()
			ItemID.MERGE_ALL:
				layers_tool._on_merge_all()
			ItemID.SHOW_ALL_LAYER:
				layers_tool._on_show_all()
			ItemID.HIDE_ALL_LAYER:
				layers_tool._on_hide_all()
			ItemID.APPLY_PREVIOUS_MOVE_TRANSFORM:
				layers_tool._on_apply_prev_move_transform()
