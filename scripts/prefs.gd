extends Node

const PATH := "user://forreals.cfg"

var _data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(text)
	if typeof(d) == TYPE_DICTIONARY:
		_data = d


func get_v(key: String, fallback: Variant) -> Variant:
	return _data.get(key, fallback)


func set_v(key: String, value: Variant) -> void:
	_data[key] = value
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_data))
	f.close()
