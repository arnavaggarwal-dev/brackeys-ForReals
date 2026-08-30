class_name RightColumn
extends RefCounted

static func build() -> Control:
	var col := Style.vbox(0)

	var head := Style.hbox(8)
	head.add_child(Style.label(Game.day_name(), Style.ui_b, 18, Style.INK))
	head.add_child(Style.grow())
	head.add_child(Style.live_num(
		func() -> String: return Game.compact(Game.followers), 13, Style.HOT
	))
	head.add_child(Style.label("followers", Style.ui_r, 14, Style.HOT))
	col.add_child(head)
	col.add_child(Style.spacer(8))

	var clock := Meter.new(Game.day_fraction(), Style.BAR_FILL, 0, 20)
	clock.name = "day_meter"
	col.add_child(clock)
	col.add_child(Style.spacer(18))

	col.add_child(Style.group("Trending today", _trends_box()))
	col.add_child(Style.spacer(22))
	col.add_child(Style.group("Follow Suggestions", _suggestions_box()))
	col.add_child(Style.spacer(22))
	col.add_child(Style.group("Today", _today_box()))
	col.add_child(Style.spacer(22))
	if Game.assets_open():
		col.add_child(Style.group("Assets", _assets_box()))
		col.add_child(Style.spacer(22))
	if Game.agents_open():
		col.add_child(Style.group("People", _agents_box()))
		col.add_child(Style.spacer(10))
	return col


static func _assets_box() -> Control:
	var col := Style.vbox(6)
	col.add_child(_rate_line())
	col.add_child(_bulk_row())

	var list := PanelContainer.new()
	list.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	var rows := Style.vbox(0)
	for a: Dictionary in Data.ASSETS:
		rows.add_child(_asset_row(a))
	list.add_child(rows)
	col.add_child(list)
	return col


static func _rate_line() -> Control:
	var well := Dialog.well(8)
	var col := Style.vbox(3)
	var row := Style.hbox(8)
	row.add_child(Style.label("earning", Style.ui_r, 13, Style.INK_SOFT))
	row.add_child(Style.grow())
	row.add_child(Style.live_num(
		func() -> String: return "%s /sec" % Game.compact(int(Game.followers_per_second())),
		12, Style.OK_GREEN
	))
	col.add_child(row)

	var heat := Style.hbox(8)
	heat.add_child(Style.label("costing", Style.ui_r, 13, Style.INK_SOFT))
	heat.add_child(Style.grow())
	heat.add_child(Style.live_num(
		func() -> String: return "+%.2f susp/sec" % Game.heat_per_second(), 12, Style.ALARM
	))
	col.add_child(heat)

	var ratio := Style.hbox(8)
	ratio.add_child(Style.label("vs cooling", Style.ui_r, 13, Style.INK_SOFT))
	ratio.add_child(Style.grow())
	ratio.add_child(Style.live(
		func() -> String:
			var r := Game.heat_ratio()
			return "x%.2f  %s" % [r, "sustainable" if r <= 1.0 else "climbing"],
		Style.tiny_b, 11, Style.INK, 1
	))
	col.add_child(ratio)
	well.add_child(col)
	return well


static func _bulk_row() -> Control:
	var row := Style.hbox(8)
	row.add_child(Style.label("buy", Style.ui_r, 12, Style.INK_SOFT))
	row.add_child(Style.grow())
	for step: int in Data.BULK_STEPS:
		var t := Tappable.new(Vector4(9, 3, 9, 4), Tappable.Look.LIST)
		t.set_selected(Game.bulk == step)
		t.add_content(Style.num("x%d" % step, 11, Style.INK))
		var pick := step
		t.pressed.connect(func() -> void:
			Game.bulk = pick
			Game.view_dirty.emit())
		row.add_child(t)
	return row


static func _pause_button(id: String) -> Control:
	var off := Game.is_paused(id)
	var t := Tappable.new(Vector4(7, 3, 7, 4), Tappable.Look.LIST)
	t.add_content(Style.num("off" if off else "on", 9, Style.ALARM if off else Style.OK_GREEN))
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.pressed.connect(func() -> void: Game.toggle_paused(id))
	return t


static func _asset_row(a: Dictionary) -> Control:
	var id := String(a["id"])
	var owned := Game.asset_count(id)
	var want := Game.bulk
	var got := Game.bulk_affordable(a, want)
	var affordable := got > 0

	var t := Tappable.new(Vector4(8, 6, 8, 7), Tappable.Look.LIST)
	t.set_enabled(affordable)

	var row := Style.hbox(8)
	var col := Style.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var head := Style.hbox(6)
	head.add_child(Style.label(
		String(a["name"]), Style.ui_b, 13,
		Style.INK if affordable else Style.INK_FAINT
	))
	if owned > 0:
		head.add_child(Style.num("x%d" % owned, 11, Style.OK_GREEN))
	col.add_child(head)
	col.add_child(Style.body(String(a["note"]), Style.ui_r, 11, Style.INK_FAINT, 2))
	var earns := "+%s/sec" % Game.compact(int(a["fps"]))
	if int(a.get("posts", 0)) > 0:
		earns = "+%d post/day" % int(a["posts"])
	col.add_child(Style.num(
		"%s  ·  +%.2f susp" % [earns, float(a["susp"])], 9, Style.INK_SOFT
	))
	row.add_child(col)

	var buying: int = maxi(1, got)
	var price := Style.live_num(
		func() -> String:
			var n := maxi(1, Game.bulk_affordable(a, Game.bulk))
			return "£%s%s" % [
				Game.commas(Game.bulk_cost(a, n)), "" if n == 1 else " x%d" % n
			],
		12, Style.INK if affordable else Style.INK_FAINT
	)
	price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(price)

	if owned > 0:
		row.add_child(_pause_button(id))

	t.add_content(row)
	if affordable:
		t.pressed.connect(func() -> void: Game.buy_asset(a, Game.bulk))
	return t


static func _agents_box() -> Control:
	var col := Style.vbox(6)
	col.add_child(_bulk_row())

	var list := PanelContainer.new()
	list.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	var rows := Style.vbox(0)
	for a: Dictionary in Data.AGENTS:
		rows.add_child(_agent_row(a))
	list.add_child(rows)
	col.add_child(list)
	return col


static func _agent_row(a: Dictionary) -> Control:
	var id := String(a["id"])
	var owned := Game.agent_count(id)
	var got := Game.bulk_agents_affordable(a, Game.bulk)
	var affordable := got > 0

	var t := Tappable.new(Vector4(8, 6, 8, 7), Tappable.Look.LIST)
	t.set_enabled(affordable)

	var row := Style.hbox(8)
	var col := Style.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var head := Style.hbox(6)
	head.add_child(Style.label(
		String(a["name"]), Style.ui_b, 13, Style.INK if affordable else Style.INK_FAINT
	))
	if owned > 0:
		head.add_child(Style.num("x%d" % owned, 11, Style.OK_GREEN))
	col.add_child(head)
	col.add_child(Style.body(String(a["note"]), Style.ui_r, 11, Style.INK_FAINT, 2))
	col.add_child(Style.num(
		"1 every %s  ·  +%.3f susp" % [Game.duration(float(a["every"])), float(a["susp"])],
		9, Style.INK_SOFT
	))
	row.add_child(col)

	var price := Style.live_num(
		func() -> String:
			var n := maxi(1, Game.bulk_agents_affordable(a, Game.bulk))
			return "£%s%s" % [
				Game.commas(Game.bulk_agent_cost(a, n)), "" if n == 1 else " x%d" % n
			],
		12, Style.INK if affordable else Style.INK_FAINT
	)
	price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(price)

	if owned > 0:
		row.add_child(_pause_button(id))

	t.add_content(row)
	if affordable:
		t.pressed.connect(func() -> void: Game.buy_agent(a, Game.bulk))
	return t


static func _today_box() -> Control:
	var well := Dialog.well(9)
	var col := Style.vbox(6)
	col.add_child(_line("day length", Game.duration(Game.day_length())))
	col.add_child(_line("follows spent", str(Game.follows_today)))
	if Game.follow_seconds_today > 0.0:
		col.add_child(_line("doomscrolled", Game.duration(Game.follow_seconds_today)))
	col.add_child(_line("likes given", str(Game.likes_given_today)))
	if Game.goodwill() > 0.0:
		col.add_child(_line(
			"goodwill", "+%d%% reach" % int(round(Game.goodwill() * 100.0)), Style.OK_GREEN
		))
	well.add_child(col)
	return well


static func _line(key: String, value: String, ink: Color = Style.INK) -> Control:
	var row := Style.hbox(8)
	row.add_child(Style.label(key, Style.ui_r, 13, Style.INK_SOFT))
	row.add_child(Style.grow())
	row.add_child(Style.num(value, 11, ink))
	return row


static func _trends_box() -> Control:
	var col := Style.vbox(9)
	col.add_child(_source_line())
	for tag: String in Game.trending:
		col.add_child(_trend(tag))
	return col


static func _source_line() -> Control:
	var live := Trends.status == "live"
	var fetching := Trends.status == "fetching"
	var row := Style.hbox(6)

	if fetching:
		var art := SpriteAnim.make("loading", 13.0)
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(art)
	else:
		var dot := Icon.new(Icon.Kind.DOT, 9, Style.OK_GREEN if live else Style.INK_FAINT)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)

	var text := "offline - shuffled"
	if live:
		text = "live - wikipedia"
	elif fetching:
		text = "asking wikipedia"
	row.add_child(Style.num(
		text, 9, Style.OK_GREEN if live else Style.INK_FAINT
	))
	return row


static func _trend(tag: String) -> Control:
	var picked: bool = Game.draft_tags().has(tag)
	var t := Tappable.new(Vector4(6, 4, 6, 5), Tappable.Look.FLAT)

	var col := Style.vbox(4)
	var row := Style.hbox(6)
	var f := SpriteAnim.make("fire", 15.0)
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(f)
	row.add_child(Style.label(tag, Style.ui_m, 15, Style.ALARM if picked else Style.INK))
	row.add_child(Style.grow())
	if picked:
		var tick := Icon.new(Icon.Kind.CHECK, 13, Style.OK_GREEN)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tick)
	col.add_child(row)
	col.add_child(Meter.new(Game.trend_heat(tag), Style.ALARM, 0, 14))
	t.add_content(col)

	t.pressed.connect(func() -> void:
		if Game.can_post():
			Composer.open()
		else:
			Game.toast_requested.emit(
				"No post left today", "the trend will have moved by then", true
			))
	return t


static func _suggestions_box() -> Control:
	var list := PanelContainer.new()
	list.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	var col := Style.vbox(0)
	for acc: Dictionary in _suggestions():
		col.add_child(_suggestion(acc))
	list.add_child(col)
	return list


static func _suggestions() -> Array:
	return Game.suggestions.filter(
		func(a: Dictionary) -> bool: return not Game.is_following(String(a["h"]))
	)


static func _suggestion(acc: Dictionary) -> Control:
	var available := Game.account_available(acc)
	var t := Tappable.new(Vector4(7, 6, 7, 7), Tappable.Look.LIST)
	t.set_enabled(available)

	var row := Style.hbox(9)
	var av := Avatar.for_account(acc, 32)
	if not available:
		av.modulate.a = 0.45
	row.add_child(av)

	var meta := Style.vbox(1)
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var head := Style.hbox(6)
	head.add_child(Style.body(
		String(acc["n"]), Style.ui_b, 14, Style.INK if available else Style.INK_FAINT, 1
	))
	head.add_child(Style.grow())
	head.add_child(Style.num(
		Game.compact(int(acc.get("followers", 0))), 9, Style.INK_FAINT
	))
	meta.add_child(head)
	meta.add_child(Style.label("@" + String(acc["h"]), Style.ui_r, 12, Style.INK_FAINT))
	if acc.has("bio"):
		meta.add_child(Style.body(
			String(acc["bio"]), Style.ui_r, 11, Style.INK_FAINT, 2
		))
	meta.add_child(Style.label(
		String(Data.TOPICS[acc["topic"]]["tag"]), Style.ui_m, 13,
		Style.topic_color(String(acc["topic"])) if available else Style.INK_FAINT
	))
	if not available:
		meta.add_child(Style.num(
			"unlocks at %s followers" % Game.compact(int(acc["at"])), 9, Style.INK_FAINT
		))
	row.add_child(meta)

	t.add_content(row)
	if available:
		t.pressed.connect(func() -> void: Game.follow(String(acc["h"])))
	return t
