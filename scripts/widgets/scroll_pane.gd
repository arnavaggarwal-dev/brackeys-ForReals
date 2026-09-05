class_name ScrollPane
extends ScrollContainer

const SCENE := "res://scenes/widgets/scroll_pane.tscn"

@export var pad := Vector4i(10, 10, 18, 12)

@onready var body: VBoxContainer = $Pad/Body

@onready var _pad: MarginContainer = $Pad


static func make() -> ScrollPane:
	return load(SCENE).instantiate()


func _ready() -> void:
	_pad.add_theme_constant_override("margin_left", pad.x)
	_pad.add_theme_constant_override("margin_top", pad.y)
	_pad.add_theme_constant_override("margin_right", pad.z)
	_pad.add_theme_constant_override("margin_bottom", pad.w)
	style_bar(get_v_scroll_bar())
	DragScroll.attach(self)


func swap(view: Control) -> void:
	var keep := scroll_vertical
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(view)
	set_deferred("scroll_vertical", keep)


func clear() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()


static func style_bar(bar: VScrollBar) -> void:
	bar.custom_minimum_size.x = 14
	bar.add_theme_stylebox_override("scroll", Style.plain_box(Style.SURFACE_HI))
	bar.add_theme_stylebox_override("scroll_focus", Style.plain_box(Style.SURFACE_HI))
	bar.add_theme_stylebox_override("grabber", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED))
	bar.add_theme_stylebox_override("grabber_highlight", Style.box(Style.SURFACE_HI, BevelBox.Style3D.RAISED))
	bar.add_theme_stylebox_override("grabber_pressed", Style.box(Style.SURFACE, BevelBox.Style3D.PRESSED))
