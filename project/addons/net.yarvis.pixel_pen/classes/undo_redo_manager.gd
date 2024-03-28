@tool
class_name UndoRedoManager
extends RefCounted


const MAX_CACHE : int = 3
const MAX_STEP : int = 50

var _cache : Array[CUndoRedo] = []
var _current_index : int = 0


func _init():
	clear_history()


func get_cache(index) -> CUndoRedo:
	for v in _cache:
		if v.index == _current_index:
			return v
	return null


func get_index(current_index) -> int:
	for i in range(_cache.size()):
		if _cache[i].index == current_index:
			return i
	return -1


func clear_history():
	_cache.clear()
	_cache.push_back(CUndoRedo.new())
	_current_index = _cache[0].index


func undo():
	var cache = get_cache(_current_index)
	if cache.has_undo():
		cache.undo()
	else:
		var index = get_index(_current_index)
		if index > 0:
			_current_index = _cache[index - 1].index
			undo()


func redo():
	var cache = get_cache(_current_index)
	if cache.has_redo():
		cache.redo()
	else:
		var index = get_index(_current_index)
		if index < _cache.size() - 1 and index != -1:
			_current_index = _cache[index + 1].index
			redo()


func create_action(name : String):
	var cache = get_cache(_current_index)
	var index = get_index(_current_index)
	var has_redo : bool = cache.has_redo()
	if has_redo:
		cache.clamp_redo_action = cache.get_current_action()
	if index < _cache.size() + 1:
		_cache = _cache.slice(0, index + 1)
	if cache.get_history_count() >= MAX_STEP or has_redo:
		_cache.push_back(CUndoRedo.new())
		if _cache.size() > MAX_CACHE:
			_cache.pop_front()
		_current_index = _cache[_cache.size() - 1].index
		cache = get_cache(_current_index)
	cache.create_action(name)


func commit_action():
	get_cache(_current_index).commit_action(false)


func add_undo_method(callable : Callable):
	get_cache(_current_index).add_undo_method(callable)


func add_undo_property(object : Object, property : String, value : Variant):
	get_cache(_current_index).add_undo_property(object, property, value)


func add_do_method(callable : Callable):
	get_cache(_current_index).add_do_method(callable)


func add_do_property(object : Object, property : String, value):
	get_cache(_current_index).add_do_property(object, property, value)


class CUndoRedo extends UndoRedo:
	var index : int = 0
	var clamp_redo_action : int = -1
	static var _index_counter = 0


	func _init():
		_index_counter += 1
		index = _index_counter


	func has_redo():
		return has_redo() and (get_current_action() < clamp_redo_action or clamp_redo_action == -1)
