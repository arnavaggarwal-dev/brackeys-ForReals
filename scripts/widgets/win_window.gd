class_name WinWindow
extends PanelContainer

const SCENE := "res://scenes/widgets/win_window.tscn"

@export var title := "Window"
@export var sunken_client := false

@onready var title_label: Label = $Column/TitleBar/Bar/Title
@onready var client: VBoxContainer = $Column/Body/Client
@onready var scroll: ScrollPane = $Column/Body/Client/Scroll
@onready var body: VBoxContainer = $Column/Body/Client/Scroll/Pad/Body

@onready var _title_panel: PanelContainer = $Column/TitleBar

var _active := true


static func make(window_title: String, sunken: bool = false) -> WinWindow:
	var w: WinWindow = load(SCENE).instantiate()
	w.title = window_title
	w.sunken_client = sunken
	return w


func _ready() -> void:
	add_theme_stylebox_override("panel", Style.frame_box(3))
	_title_panel.add_theme_stylebox_override("panel", Style.title_box(true))

	title_label.text = title
	title_label.add_theme_font_override("font", Style.ui_b)
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Style.TITLE_TEXT)

	$Column/Body.add_theme_stylebox_override(
		"panel",
		Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 3, 3, 3, 3) if sunken_client
			else Style.box(Style.SURFACE, BevelBox.Style3D.FLAT, 2, 2, 2, 2)
	)

	for button: PanelContainer in $Column/TitleBar/Bar/Buttons.get_children():
		button.add_theme_stylebox_override(
			"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 3, 2, 3, 2)
		)


func set_active(v: bool) -> void:
	if _active == v:
		return
	_active = v
	_title_panel.add_theme_stylebox_override("panel", Style.title_box(v))
	title_label.add_theme_color_override(
		"font_color", Style.TITLE_TEXT if v else Style.TITLE_TEXT_OFF
	)
