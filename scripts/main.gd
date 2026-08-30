class_name AppShell
extends Control

static var i: AppShell

const LEFT_W := 340.0
const RIGHT_W := 320.0
const EDGE := 8.0
const TASKBAR_H := Taskbar.HEIGHT
const TOAST_SCALE := Toast.SCALE

var desktop: ColorRect
var glitch_layer: ColorRect
var glitch_mat: ShaderMaterial
var shell: Control
var shell_shift: Control

var left_win: WinWindow
var centre_win: WinWindow
var right_win: WinWindow
var left_scroll: ScrollContainer
var centre_scroll: ScrollContainer
var right_scroll: ScrollContainer
var left_body: VBoxContainer
var centre_body: VBoxContainer
var right_body: VBoxContainer

var taskbar: Taskbar

var toast_layer: VBoxContainer
var veil: Control
var menu_layer: Control

var _drift := 0.0


func _ready() -> void:
	i = self
	_fit_window()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Game.view_dirty.connect(_on_view_dirty)
	Game.nav_dirty.connect(_on_view_dirty)
	Game.day_started.connect(_on_day)
	Game.glitch.connect(shake)
	Game.toast_requested.connect(show_toast)
	Game.screen_changed.connect(_on_screen)
	NukeScreen.warm()

	if DevTour.balance_only():
		DevTour.run_balance()
		get_tree().quit()
	elif DevTour.shots_only():
		DevTour.run_shots()
	elif DevTour.nuke_only():
		DevTour.run_nuke()
	elif not DevTour.enabled() and Save.load_game():
		if Game.screen != "over":
			Game.resume()
			Game.toast_requested.emit(
				"Welcome back, @%s" % Game.handle, "day %d" % Game.day, false
			)
			_report_offline()
	elif DevTour.enabled() or Save.has_save():
		SignInScreen.show_signin()
	else:
		Game.begin_prologue()
	if DevTour.enabled():
		DevTour.run()


func _report_offline() -> void:
	var r := Game.offline_report
	Game.offline_report = {}
	if r.is_empty():
		return
	var hours := float(r.get("hours", 0.0))
	var span := "%d hours" % int(round(hours)) if hours >= 1.5 else "an hour"
	Game.toast_requested.emit(
		"+%s followers while you were out" % Game.commas(int(r.get("followers", 0))),
		"your people worked %s without you" % span,
		false
	)


func _toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	if full:
		_fit_window()


func _fit_window() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var usable := DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()
	)
	var want := DisplayServer.window_get_size()
	var fit := Vector2i(
		mini(want.x, usable.size.x - 20), mini(want.y, usable.size.y - 60)
	)
	if fit == want:
		return
	DisplayServer.window_set_size(fit)
	DisplayServer.window_set_position(
		usable.position + (usable.size - fit) / 2
	)


func _build() -> void:
	desktop = ColorRect.new()
	desktop.set_anchors_preset(Control.PRESET_FULL_RECT)
	desktop.color = Style.DESKTOP
	desktop.material = _shader_mat("res://shaders/desktop.gdshader")
	desktop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desktop)

	shell_shift = Control.new()
	shell_shift.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell_shift.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(shell_shift)

	shell = Control.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.mouse_filter = Control.MOUSE_FILTER_PASS
	shell_shift.add_child(shell)

	var stack := Style.vbox(0)
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_child(stack)

	var row := Style.hbox(int(EDGE))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var desk := Style.margins(row, int(EDGE), int(EDGE), int(EDGE), 0)
	desk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(desk)

	left_win = WinWindow.new("Profile")
	left_win.custom_minimum_size.x = LEFT_W
	left_win.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll = _scroller()
	left_body = _body_of(left_scroll)
	left_win.client.add_child(left_scroll)
	row.add_child(left_win)

	centre_win = WinWindow.new("ForReals - Feed")
	centre_win.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre_win.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre_scroll = _scroller()
	centre_body = _body_of(centre_scroll)
	centre_win.client.add_child(centre_scroll)
	row.add_child(centre_win)

	right_win = WinWindow.new("Today")
	right_win.custom_minimum_size.x = RIGHT_W
	right_win.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll = _scroller()
	right_body = _body_of(right_scroll)
	right_win.client.add_child(right_scroll)
	row.add_child(right_win)

	stack.add_child(Style.spacer(EDGE))
	taskbar = Taskbar.make()
	stack.add_child(taskbar)

	glitch_layer = ColorRect.new()
	glitch_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	glitch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_mat = _shader_mat("res://shaders/glitch_fx.gdshader")
	glitch_layer.material = glitch_mat
	add_child(glitch_layer)

	toast_layer = Style.vbox(6)
	toast_layer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toast_layer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	toast_layer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_layer.offset_bottom = -(TASKBAR_H + 10.0)
	toast_layer.offset_right = -12
	toast_layer.custom_minimum_size.x = int(Toast.WIDTH * Toast.SCALE)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)

	veil = Control.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.offset_bottom = -TASKBAR_H
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	menu_layer = Control.new()
	menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_layer)


func _scroller() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_scrollbar(s.get_v_scroll_bar())

	var body := Style.vbox(0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := Style.margins(body, 10, 10, 10, 12)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(pad)
	return s


func _body_of(s: ScrollContainer) -> VBoxContainer:
	return s.get_child(0).get_child(0) as VBoxContainer


func _shader_mat(path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	return m


func style_scrollbar(bar: VScrollBar) -> void:
	bar.custom_minimum_size.x = 14
	bar.add_theme_stylebox_override("scroll", Style.plain_box(Style.SURFACE_HI))
	bar.add_theme_stylebox_override("scroll_focus", Style.plain_box(Style.SURFACE_HI))
	bar.add_theme_stylebox_override("grabber", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED))
	bar.add_theme_stylebox_override("grabber_highlight", Style.box(Style.SURFACE_HI, BevelBox.Style3D.RAISED))
	bar.add_theme_stylebox_override("grabber_pressed", Style.box(Style.SURFACE, BevelBox.Style3D.PRESSED))


func _process(delta: float) -> void:
	if not NukeScreen.warmed():
		NukeScreen.warm_progress()

	var heat: float = clampf(Game.suspicion / Data.SUSPICION_LIMIT, 0.0, 1.0)
	taskbar.refresh(heat)
	glitch_mat.set_shader_parameter("intensity", heat * 0.8)

	var clock := right_body.find_child("day_meter", true, false) as Meter
	if clock != null:
		clock.set_value(Game.day_fraction())

	if heat > 0.55 and Game.screen == "app":
		_drift += delta
		var d := Vector2(
			round(sin(_drift * 5.1) * 1.5), round(cos(_drift * 3.7) * 1.0)
		) * (heat - 0.55) * 2.2
		shell_shift.position = d
	elif shell_shift.position != Vector2.ZERO:
		shell_shift.position = Vector2.ZERO


func _on_day(_day: int) -> void:
	Sfx.blip()


func shake(strength: float) -> void:
	Sfx.shear(clampf(strength * 3.0, 0.1, 0.7))
	var tw := create_tween()
	tw.tween_method(
		func(v: float) -> void: glitch_mat.set_shader_parameter("tear", v),
		clampf(strength * 5.0, 0.15, 1.0), 0.0, 0.4
	)
	var amp: float = clampf(strength * 60.0, 2.0, 12.0)
	var kick := create_tween()
	for n in 5:
		var off := Vector2(
			round(randf_range(-amp, amp)), round(randf_range(-amp, amp))
		) * (1.0 - n / 5.0)
		kick.tween_property(shell_shift, "position", off, 0.04)
	kick.tween_property(shell_shift, "position", Vector2.ZERO, 0.06)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var alt_enter: bool = event.keycode == KEY_ENTER and event.alt_pressed
		if event.keycode == KEY_F11 or alt_enter:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return

	if not event.is_action_pressed("ui_cancel"):
		return
	if NukeScreen.running():
		return
	if StartMenu.is_open():
		StartMenu.close()
		get_viewport().set_input_as_handled()
		return
	if Game.screen == "app" and veil.get_child_count() > 0:
		Composer.close()
		Store.close()
		Dialog.close()
		get_viewport().set_input_as_handled()


func _on_view_dirty() -> void:
	render_view()


func _on_screen(s: String) -> void:
	match s:
		"app":
			clear_veil()
			render_view()
		"over":
			GameOverScreen.show_over()


func render_view() -> void:
	if Game.screen != "app":
		return
	left_win.title_label.text = "@%s" % Game.handle
	centre_win.title_label.text = "ForReals - Feed"
	right_win.title_label.text = "Today - %s" % Game.day_name()
	_swap(left_scroll, left_body, LeftColumn.build())
	_swap(centre_scroll, centre_body, CenterColumn.build())
	_swap(right_scroll, right_body, RightColumn.build())


func _swap(host: ScrollContainer, body: VBoxContainer, view: Control) -> void:
	var keep := host.scroll_vertical
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(view)
	host.set_deferred("scroll_vertical", keep)


func show_toast(title: String, sub: String, bad: bool) -> void:
	while toast_layer.get_child_count() >= 3:
		var oldest := toast_layer.get_child(0)
		toast_layer.remove_child(oldest)
		oldest.queue_free()
	toast_layer.add_child(Toast.make(title, sub, bad))
	Sfx.tick()


func restart() -> void:
	Save.clear()
	Game.reset()
	glitch_mat.set_shader_parameter("intensity", 0.0)
	glitch_mat.set_shader_parameter("tear", 0.0)
	shell_shift.position = Vector2.ZERO
	_drift = 0.0
	for body in [left_body, centre_body, right_body]:
		for c in body.get_children():
			body.remove_child(c)
			c.queue_free()
	for c in toast_layer.get_children():
		c.queue_free()
	SignInScreen.show_signin()


func quit_game() -> void:
	Save.write()
	get_tree().quit()


func mount_menu(node: Control) -> void:
	clear_menu()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(node)


func clear_menu() -> void:
	for c in menu_layer.get_children():
		c.queue_free()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func clear_veil() -> void:
	for c in veil.get_children():
		c.queue_free()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


func mount_veil(node: Control) -> void:
	clear_veil()
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.add_child(node)
