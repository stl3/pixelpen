@tool
extends Control


const shorcut : EditorShorcut = preload("../../resources/editor_shorcut.tres")

@export var select : TextureButton
@export var move : TextureButton
@export var pan : TextureButton
@export var selection : TextureButton
@export var pen : TextureButton
@export var brush : TextureButton
@export var eraser : TextureButton
@export var line : TextureButton
@export var rectangle : TextureButton
@export var fill : TextureButton
@export var color_picker : TextureButton
@export var zoom : TextureButton


func _ready():
	await get_tree().process_frame
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PEN, true)
	set_shorcut()
	PixelPen.project_file_changed.connect(func ():
			if PixelPen.current_project != null:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PEN, true)
			)


func set_shorcut():
	select.shortcut = shorcut.tool_select
	move.shortcut = shorcut.tool_move
	pan.shortcut = shorcut.tool_pan
	selection.shortcut = shorcut.tool_selection
	pen.shortcut = shorcut.tool_pen
	brush.shortcut = shorcut.tool_brush
	eraser.shortcut = shorcut.tool_eraser
	line.shortcut = shorcut.tool_line
	rectangle.shortcut = shorcut.tool_rectangle
	fill.shortcut = shorcut.tool_fill
	color_picker.shortcut = shorcut.tool_color_picker
	zoom.shortcut = shorcut.tool_zoom


func _on_select_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_SELECT, true)


func _on_move_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MOVE, true)


func _on_pan_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PAN, true)


func _on_selection_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_SELECTION, true)


func _on_pen_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PEN, true)


func _on_brush_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_BRUSH, true)


func _on_eraser_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_ERASER, true)


func _on_line_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_LINE, true)


func _on_rectangle_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_RECTANGLE, true)


func _on_fill_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_FILL, true)


func _on_color_picker_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_COLOR_PICKER, true)


func _on_zoom_pressed():
	PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_ZOOM, true)
