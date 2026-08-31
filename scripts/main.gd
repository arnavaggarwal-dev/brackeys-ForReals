class_name AppShell
extends Control

static var i: AppShell

const LEFT_W := 340.0
const RIGHT_W := 320.0
const EDGE := 8.0
const TASKBAR_H := Taskbar.HEIGHT
const TOAST_SCALE := Toast.SCALE

# A handheld interface is measured out against the real screen, not the pixel
# count. A phone is about 142mm across in landscape and 71mm in portrait, so any
# fixed unit count is unreadable in one of the two. These are interface units per
# millimetre of actual glass, which holds in both, and on any size of phone.
#
# At 5.9, body text at 13 units lands a shade over 2mm tall. A tablet is held
# further away and has room to spare, so it runs denser and keeps three columns.
const PHONE_UNITS_PER_MM := 5.9
const TABLET_UNITS_PER_MM := 5.0

# Used only when the platform will not say how big or how dense the screen is.
const FALLBACK_WIDTH := 900.0

# The largest share of the window a believable notch or gesture bar can take up.
const SAFE_AREA_SANITY := 0.25

const TABLET_INCHES := 7.5

# The three columns want 340 + 320 plus a readable feed between them, which no
# phone has room for. Below this the shell shows one window at a time instead.
const NARROW_BELOW := 1080.0

# Which window a narrow shell is showing. Ignored when all three are up.
static var narrow := false

var pane := "profile"

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
var _relaying := false
var _safe_applied := Rect2i()
var _win_applied := Vector2i.ZERO


func _ready() -> void:
	i = self
	_fit_window()
	_fit_handheld()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	get_viewport().size_changed.connect(_relayout)
	_apply_safe_area()
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


func _maybe_tutorial() -> void:
	await get_tree().create_timer(0.6).timeout
	if Game.screen == "app" and not Game.prologue and veil.get_child_count() == 0:
		Tutorial.maybe_start()


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


static func is_handheld() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


# Physical size of the whole screen on the diagonal. Zero when the platform will
# not say, which is read as a phone, that being the worse of the two to get wrong.
static func screen_inches() -> float:
	var dpi := DisplayServer.screen_get_dpi()
	var px := Vector2(DisplayServer.screen_get_size())
	if dpi <= 0 or px.x <= 0.0 or px.y <= 0.0:
		return 0.0
	return px.length() / float(dpi)


# How many interface units to lay across the window, so that a millimetre of real
# screen always holds about the same amount of text whichever way up it is held.
func _wanted_width(win: Vector2) -> float:
	var dpi := DisplayServer.screen_get_dpi()
	if dpi <= 0:
		return FALLBACK_WIDTH
	var mm := win.x / float(dpi) * 25.4
	var per_mm := TABLET_UNITS_PER_MM if screen_inches() >= TABLET_INCHES else PHONE_UNITS_PER_MM
	return maxf(360.0, mm * per_mm)


func _fit_handheld() -> void:
	if not is_handheld():
		return
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return
	# Godot fits the 1280x720 base into the window first; the factor is applied on
	# top of that, so it is worked back out of the width the interface wants.
	var base := minf(win.x / 1280.0, win.y / 720.0)
	var want := _wanted_width(win)
	get_tree().root.content_scale_factor = win.x / (want * base)
	narrow = want < NARROW_BELOW


# Turning the phone over changes how much room there is, and on a tablet it also
# decides whether three columns still fit, which needs the shell built again.
func _relayout() -> void:
	if _relaying:
		return
	_relaying = true
	var was := narrow
	_fit_handheld()
	if narrow != was and not NukeScreen.running():
		Composer.close()
		Store.close()
		Dialog.close()
		StartMenu.close()
		for child in get_children():
			remove_child(child)
			child.queue_free()
		_build()
		render_view()
	_apply_safe_area()
	_relaying = false


# Keeps the three windows clear of a notch, a punch hole, or the gesture bar.
#
# Checked every frame rather than on size_changed alone, because the safe area
# arrives after the rotation does. Asked too early, Android answers for the
# orientation the phone has just left: a landscape rectangle against a portrait
# window, which reaches past the right edge and takes the shell with it.
func _apply_safe_area() -> void:
	if shell == null or not is_handheld():
		return
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return
	if win == _win_applied and safe == _safe_applied:
		return

	var l := maxf(0.0, float(safe.position.x))
	var t := maxf(0.0, float(safe.position.y))
	var r := maxf(0.0, float(win.x - safe.position.x - safe.size.x))
	var b := maxf(0.0, float(win.y - safe.position.y - safe.size.y))
	# No real notch eats a quarter of the screen, so anything claiming to is a
	# rectangle meant for the other orientation and is left alone until it agrees.
	if l + r > float(win.x) * SAFE_AREA_SANITY or t + b > float(win.y) * SAFE_AREA_SANITY:
		return

	_win_applied = win
	_safe_applied = safe
	var to_ui := size / Vector2(win)
	# The desktop is inset with the shell, so the band beside a camera cutout is
	# left to the black underlay and reads as bezel instead of a teal stripe.
	for c: Control in [shell, desktop]:
		c.offset_left = l * to_ui.x
		c.offset_top = t * to_ui.y
		c.offset_right = -r * to_ui.x
		c.offset_bottom = -b * to_ui.y


func _build() -> void:
	# A fresh shell has no inset yet, whatever was last applied to the old one.
	_win_applied = Vector2i.ZERO
	_safe_applied = Rect2i()

	var bezel := ColorRect.new()
	bezel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezel.color = Color.BLACK
	bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bezel)

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
	if not narrow:
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
	if not narrow:
		right_win.custom_minimum_size.x = RIGHT_W
	right_win.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll = _scroller()
	right_body = _body_of(right_scroll)
	right_win.client.add_child(right_scroll)
	row.add_child(right_win)

	if narrow:
		for w: WinWindow in [left_win, centre_win, right_win]:
			w.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	stack.add_child(Style.spacer(EDGE))
	taskbar = Taskbar.make()
	stack.add_child(taskbar)
	show_pane(pane)

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


# On a phone the three windows are stacked on top of each other and the taskbar
# picks between them, which is what a taskbar was always for.
func show_pane(id: String) -> void:
	if not narrow:
		return
	pane = id
	left_win.visible = id == "profile"
	centre_win.visible = id == "feed"
	right_win.visible = id == "today"
	if taskbar != null:
		taskbar.mark_pane(id)


# The tutorial and anything else that talks about one of the three columns needs
# that column to actually be the one on screen.
func show_pane_for(where: String) -> void:
	match where:
		"left":
			show_pane("profile")
		"centre":
			show_pane("feed")
		"right":
			show_pane("today")


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
	DragScroll.attach(s)
	return s


func _body_of(s: ScrollContainer) -> VBoxContainer:
	# The scroller also carries a DragScroll, so the padding is found by type.
	for child in s.get_children():
		if child is MarginContainer:
			return child.get_child(0) as VBoxContainer
	return null


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
	_apply_safe_area()
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
	if _go_back():
		get_viewport().set_input_as_handled()


# Escape on the desktop and the Android back gesture both mean "out of this one
# thing". Neither may throw the run away, which is why quit_on_go_back is off.
func _go_back() -> bool:
	if NukeScreen.running():
		return false
	if StartMenu.is_open():
		StartMenu.close()
		return true
	if Game.screen == "app" and veil.get_child_count() > 0:
		Composer.close()
		Store.close()
		Dialog.close()
		return true
	return false


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if not _go_back():
		StartMenu.toggle()


func _on_view_dirty() -> void:
	render_view()


func _on_screen(s: String) -> void:
	match s:
		"app":
			clear_veil()
			render_view()
			if not Game.prologue:
				_maybe_tutorial()
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
