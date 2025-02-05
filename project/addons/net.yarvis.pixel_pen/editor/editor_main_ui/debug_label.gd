@tool
extends Label


var data_debug : Dictionary = {}


func _ready():
	visible = false
	text = ""
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.debug_log.connect(func(key, value):
			data_debug[key] = value
			)


func _process(_delta):
	if not PixelPen.need_connection(get_window()):
		text = ""
		return
	var txt = str("FPS: ", Engine.get_frames_per_second())
	data_debug["CPPVersion"] = PixelPen.utils.version()
	data_debug["Memory"] = str(Performance.get_monitor(Performance.MEMORY_STATIC)/1000000, "/",
			Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1000000, " mb")
	for key in data_debug.keys():
		txt += str("\n", key , ": ", data_debug[key])
	text = txt


func _exit_tree():
	text = ""
