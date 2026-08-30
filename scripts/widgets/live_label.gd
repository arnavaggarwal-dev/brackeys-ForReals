class_name LiveLabel
extends Label

var source: Callable
var _last := ""


func _init(fn: Callable) -> void:
	source = fn
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if not source.is_valid():
		return
	var next: String = source.call()
	if next != _last:
		_last = next
		text = next
