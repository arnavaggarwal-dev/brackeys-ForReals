# Renders the launcher icons Android and iOS ask for out of icon.svg, so the
# 32x32 original stays the single source of truth.
#
#   godot --headless --path . --script res://tools/make_mobile_icons.gd
extends SceneTree

const SRC := "res://icon.svg"
const ANDROID_OUT := "res://assets/android"
const IOS_OUT := "res://assets/ios"

# Android crops an adaptive icon hard, so the artwork sits in the middle third.
const ADAPTIVE := 432
const ADAPTIVE_ART := 264
const BACKDROP := Color(0.0, 0.502, 0.502, 1.0)

# iOS draws no background of its own and rejects an icon with an alpha channel,
# so every one of these is flattened onto the same teal the game boots to.
const IOS_SIZES := [40, 76, 80, 120, 152, 167, 180, 1024]


func _initialize() -> void:
	var svg := FileAccess.get_file_as_string(SRC)
	if svg == "":
		push_error("ICONS: could not read %s" % SRC)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ANDROID_OUT)
	_write(_square(svg, 192), ANDROID_OUT, "icon_192.png")
	_write(_foreground(svg), ANDROID_OUT, "adaptive_foreground_432.png")
	_write(_background(ADAPTIVE), ANDROID_OUT, "adaptive_background_432.png")

	DirAccess.make_dir_recursive_absolute(IOS_OUT)
	for px: int in IOS_SIZES:
		_write(_opaque(svg, px), IOS_OUT, "icon_%d.png" % px)
	quit()


func _square(svg: String, px: int) -> Image:
	var img := Image.new()
	# 32 is the source viewBox, so the scale is a whole number and no pixel smears.
	if img.load_svg_from_string(svg, float(px) / 32.0) != OK:
		push_error("ICONS: could not rasterise the svg")
		quit(1)
	img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != px:
		img.resize(px, px, Image.INTERPOLATE_NEAREST)
	return img


func _opaque(svg: String, px: int) -> Image:
	var sheet := _background(px)
	sheet.blend_rect(_square(svg, px), Rect2i(0, 0, px, px), Vector2i.ZERO)
	sheet.convert(Image.FORMAT_RGB8)
	return sheet


func _foreground(svg: String) -> Image:
	var art := _square(svg, ADAPTIVE_ART)
	var sheet := Image.create_empty(ADAPTIVE, ADAPTIVE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var at := (ADAPTIVE - ADAPTIVE_ART) / 2
	sheet.blit_rect(art, Rect2i(0, 0, ADAPTIVE_ART, ADAPTIVE_ART), Vector2i(at, at))
	return sheet


func _background(px: int) -> Image:
	var img := Image.create_empty(px, px, false, Image.FORMAT_RGBA8)
	img.fill(BACKDROP)
	return img


func _write(img: Image, dir: String, name: String) -> void:
	var path := "%s/%s" % [dir, name]
	if img.save_png(path) != OK:
		push_error("ICONS: could not write %s" % path)
		quit(1)
		return
	print("ICONS: %s  %dx%d" % [name, img.get_width(), img.get_height()])
