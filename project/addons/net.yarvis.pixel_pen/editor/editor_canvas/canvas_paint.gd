@tool
extends RefCounted


const Tool := preload("tool.gd")
const SelectTool := preload("select_tool.gd")
const MoveTool := preload("move_tool.gd")
const PanTool := preload("pan_tool.gd")
const PenTool := preload("pen_tool.gd")
const BrushTool := preload("brush_tool.gd")
const SelectionTool := preload("selection_tool.gd")
const RectangleTool := preload("rectangle_tool.gd")
const LineTool := preload("line_tool.gd")
const FillTool := preload("fill_tool.gd")
const ColorPickerTool := preload("color_picker_tool.gd")
const ZoomTool := preload("zoom_tool.gd")

var tool : Tool = Tool.new():
	get:
		match tool.active_tool_type:
			PixelPen.ToolBox.TOOL_SELECT:
				if tool.tool_type != PixelPen.ToolBox.TOOL_SELECT:
					tool = SelectTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_MOVE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_MOVE:
					tool = MoveTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_PAN:
				if tool.tool_type != PixelPen.ToolBox.TOOL_PAN:
					tool = PanTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_PEN:
				if tool.tool_type != PixelPen.ToolBox.TOOL_PEN:
					tool = PenTool.new(PixelPen.ToolBox.TOOL_PEN)
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_BRUSH:
				if tool.tool_type != PixelPen.ToolBox.TOOL_BRUSH:
					tool = BrushTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_ERASER:
				if tool.tool_type != PixelPen.ToolBox.TOOL_ERASER:
					tool = PenTool.new(PixelPen.ToolBox.TOOL_ERASER)
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_SELECTION:
				if tool.tool_type != PixelPen.ToolBox.TOOL_SELECTION:
					tool = SelectionTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_LINE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_LINE:
					tool = LineTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_RECTANGLE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_RECTANGLE:
					tool = RectangleTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_FILL:
				if tool.tool_type != PixelPen.ToolBox.TOOL_FILL:
					tool = FillTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_COLOR_PICKER:
				if tool.tool_type != PixelPen.ToolBox.TOOL_COLOR_PICKER:
					tool = ColorPickerTool.new()
					PixelPen.toolbox_just_changed.emit()
			PixelPen.ToolBox.TOOL_ZOOM:
				if tool.tool_type != PixelPen.ToolBox.TOOL_ZOOM:
					tool = ZoomTool.new()
					PixelPen.toolbox_just_changed.emit()
			_:
				if tool.active_tool_type != tool.tool_type:
					tool = Tool.new()
					tool.tool_type = tool.active_tool_type
					PixelPen.toolbox_just_changed.emit()
		return tool


func _init(node : Node2D):
	tool.node = node


func on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if tool._can_draw or _can_draw_exeption():
		tool._on_mouse_pressed(mouse_position, callback)


func on_mouse_released(mouse_position : Vector2, callback : Callable):
	if tool._can_draw or _can_draw_exeption():
		tool._on_mouse_released(mouse_position, callback)


func on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if tool._can_draw or _can_draw_exeption():
		tool._on_mouse_motion(mouse_position, event_relative, callback)


func on_shift_pressed(pressed : bool):
	if tool._can_draw or _can_draw_exeption():
		tool._on_shift_pressed(pressed)


func on_draw_cursor(mouse_position : Vector2):
	if tool._can_draw or _can_draw_exeption():
		tool._on_draw_cursor(mouse_position)
	else:
		# Draw cannot draw hint shape
		tool.draw_invalid_cursor(mouse_position)


func on_draw_hint(mouse_position : Vector2):
	tool._on_draw_hint(mouse_position)


func _can_draw_exeption():
	var exeption : bool = tool.tool_type == PixelPen.ToolBox.TOOL_PAN
	exeption = exeption or tool.tool_type == PixelPen.ToolBox.TOOL_SELECTION
	exeption = exeption or tool.tool_type == PixelPen.ToolBox.TOOL_COLOR_PICKER
	exeption = exeption or tool.tool_type == PixelPen.ToolBox.TOOL_ZOOM
	return exeption
