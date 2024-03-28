@tool
class_name ThemeConfig
extends Node


@export_enum("Main UI:0", "Layer:1") var type : int
@export_category("Style")
@export var main_panel_color : Color = Color(0.133, 0.133, 0.133, 1.0)
@export var box_panel_color : Color = Color(0.23, 0.23, 0.23, 1.0)
@export var box_panel_darker_color : Color = Color(0.15, 0.15, 0.15, 1.0)
@export var box_panel_title_color : Color = Color(0.28, 0.28, 0.28, 1.0)
@export var canvas_base_mode_color : Color = Color(0.38, 0.38, 0.38, 1.0)
@export var canvas_sample_mode_color : Color = Color(0.18, 0.18, 0.30, 1.0)
@export var layer_placeholder_color : Color = Color(0.17, 0.17, 0.17, 1.0)
@export var layer_head_color : Color = Color(0.2, 0.2, 0.2, 1.0)
@export var layer_body_color : Color = Color(0.19, 0.19, 0.19, 1.0)
@export var layer_active_color : Color = Color(0.23, 0.23, 0.23, 1.0)

@export_category("Editor Main UI")
@export var editor_main_ui : Control
@export var main_panel : Panel
@export var main_menu : Panel
@export var toolbox_panel : Panel
@export var palette_panel : Panel
@export var palette_title_panel : Panel
@export var subtool_panel : Panel
@export var preview_panel : Panel
@export var preview_wrapper_panel : ColorRect
@export var preview_title_panel : Panel
@export var layer_panel : Panel
@export var layers_wrapper_panel : Panel
@export var layer_title_panel : Panel

@export_category("Layer UI")
@export var wrapper_layer_control : ColorRect
@export var head_layer_control : ColorRect
@export var detached_layer_control : ColorRect


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


func _on_theme_changed():
	if type == 0:
		editor_main_ui.canvas_color_base = canvas_base_mode_color
		editor_main_ui.canvas_color_sample = canvas_sample_mode_color
		
		var main_panel_style : StyleBoxFlat = get_main_panel_style()
		var box_panel_style : StyleBoxFlat = get_box_panel_style()
		var box_panel_darker_style : StyleBoxFlat = get_box_panel_style_darker()
		var box_panel_title_style : StyleBoxFlat = get_box_panel_title_style()
		
		main_panel.add_theme_stylebox_override("panel", main_panel_style)
		
		main_menu.add_theme_stylebox_override("panel", box_panel_style)
		toolbox_panel.add_theme_stylebox_override("panel", box_panel_style)
		
		palette_panel.add_theme_stylebox_override("panel", box_panel_style)
		palette_title_panel.add_theme_stylebox_override("panel", box_panel_title_style)
		
		subtool_panel.add_theme_stylebox_override("panel", box_panel_style)
		
		preview_panel.add_theme_stylebox_override("panel", box_panel_style)
		preview_wrapper_panel.color = box_panel_darker_color
		preview_title_panel.add_theme_stylebox_override("panel", box_panel_title_style)
		
		layer_panel.add_theme_stylebox_override("panel", box_panel_style)
		layers_wrapper_panel.add_theme_stylebox_override("panel", box_panel_darker_style)
		layer_title_panel.add_theme_stylebox_override("panel", box_panel_title_style)
	
	elif type == 1:
		wrapper_layer_control.default_color = layer_body_color
		wrapper_layer_control.active_color = layer_active_color
		wrapper_layer_control.color = layer_placeholder_color
		head_layer_control.color = layer_head_color
		detached_layer_control.color = box_panel_darker_color


func get_main_panel_style() -> StyleBoxFlat:
	var m = StyleBoxFlat.new()
	m.bg_color = main_panel_color
	return m


func get_box_panel_style() -> StyleBoxFlat:
	var m = StyleBoxFlat.new()
	m.bg_color = box_panel_color
	return m


func get_box_panel_style_darker() -> StyleBoxFlat:
	var m = StyleBoxFlat.new()
	m.bg_color = box_panel_darker_color
	return m


func get_box_panel_title_style() -> StyleBoxFlat:
	var m = StyleBoxFlat.new()
	m.bg_color = box_panel_title_color
	return m
