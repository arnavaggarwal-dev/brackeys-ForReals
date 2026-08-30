extends Node3D

signal flashed
signal finished

const BOMB := "res://assets/3d/bomb.glb"
const KABOOM := "res://assets/audio/kaboom.mp3"

const START_Y := 18.0
const GROUND_Y := -5.4
const GRAVITY := 11.0
const AFTER_BOOM := 3.6

var _bomb: Node3D
var _pfp: MeshInstance3D
var _cam: Camera3D
var _fire: GPUParticles3D
var _smoke: GPUParticles3D
var _flash: OmniLight3D
var _boom: AudioStreamPlayer

var _vel := 1.2
var _spin := Vector3.ZERO
var _falling := true
var _shake := 0.0
var _t := 0.0
var _since_boom := 0.0


func _ready() -> void:
	_cam = $Camera
	_build_ground()
	_build_pfp()
	_build_bomb()
	_build_particles()

	_flash = OmniLight3D.new()
	_flash.position = Vector3(0.0, GROUND_Y + 1.0, 0.0)
	_flash.light_color = Color(1.0, 0.75, 0.35)
	_flash.light_energy = 0.0
	_flash.omni_range = 90.0
	add_child(_flash)

	_boom = AudioStreamPlayer.new()
	_boom.stream = NukeScreen.take(KABOOM)
	_boom.bus = "Master"
	add_child(_boom)

	_spin = Vector3(randf_range(3.5, 6.0), randf_range(-2.5, 2.5), randf_range(4.0, 7.5))


func _build_bomb() -> void:
	_bomb = Node3D.new()
	_bomb.position = Vector3(0.0, START_Y, 0.0)
	add_child(_bomb)

	var model: Node3D = NukeScreen.take(BOMB).instantiate()
	model.rotation = Vector3(0.0, 0.0, -PI / 2.0)
	model.position = Vector3(0.0, 1.4, 0.0)
	model.scale = Vector3.ONE * 0.85
	_bomb.add_child(model)


func _build_pfp() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(4.0, 4.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(Avatar.PERSONAS[int(Game.avatar.get("persona", 0))])
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	quad.material = mat

	_pfp = MeshInstance3D.new()
	_pfp.mesh = quad
	_pfp.position = Vector3(0.0, GROUND_Y + 1.4, 0.0)
	add_child(_pfp)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(120.0, 120.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.46, 0.42, 0.37)
	mat.roughness = 1.0
	plane.material = mat
	($Ground as MeshInstance3D).mesh = plane
	($Ground as MeshInstance3D).position.y = GROUND_Y - 1.6


func _build_particles() -> void:
	_fire = _emitter(
		190, 1.25, 1.0,
		_ramp([Color(1.0, 0.95, 0.62, 1.0), Color(1.0, 0.45, 0.06, 1.0),
			Color(0.55, 0.09, 0.03, 0.8), Color(0.12, 0.03, 0.01, 0.0)]),
		0.34
	)
	var fm := _fire.process_material as ParticleProcessMaterial
	fm.initial_velocity_min = 4.0
	fm.initial_velocity_max = 13.0
	fm.gravity = Vector3(0.0, -4.0, 0.0)
	fm.scale_min = 1.0
	fm.scale_max = 2.8
	fm.damping_min = 7.0
	fm.damping_max = 13.0
	_light_up(_fire, true)

	_smoke = _emitter(
		130, 4.4, 0.7,
		_ramp([Color(0.30, 0.27, 0.25, 0.0), Color(0.16, 0.15, 0.14, 0.95),
			Color(0.11, 0.10, 0.10, 0.6), Color(0.08, 0.07, 0.07, 0.0)]),
		0.7
	)
	var sm := _smoke.process_material as ParticleProcessMaterial
	sm.initial_velocity_min = 2.0
	sm.initial_velocity_max = 6.0
	sm.gravity = Vector3(0.0, 4.0, 0.0)
	sm.scale_min = 1.6
	sm.scale_max = 4.2
	sm.damping_min = 1.0
	sm.damping_max = 3.0
	sm.spread = 55.0
	_light_up(_smoke, false)


func _emitter(
	amount: int, life: float, burst: float, ramp: GradientTexture1D, radius: float
) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.explosiveness = burst
	p.one_shot = true
	p.emitting = false
	p.position = Vector3(0.0, GROUND_Y + 0.6, 0.0)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 1.0
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 80.0
	pm.color_ramp = ramp
	p.process_material = pm

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	p.draw_pass_1 = mesh
	add_child(p)
	return p


func _light_up(p: GPUParticles3D, glowing: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glowing:
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.55, 0.15)
		mat.emission_energy_multiplier = 1.5
	(p.draw_pass_1 as SphereMesh).material = mat


func _ramp(stops: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.55, 1.0])
	g.colors = PackedColorArray(stops)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _process(delta: float) -> void:
	_t += delta

	if _pfp != null and _pfp.visible:
		_pfp.rotation.y += delta * 1.8
		_pfp.position.y = GROUND_Y + 1.4 + sin(_t * 2.2) * 0.12

	if _falling:
		_vel += GRAVITY * delta
		_bomb.position.y -= _vel * delta
		_bomb.position.x = sin(_t * 2.3) * 2.6
		_bomb.position.z = sin(_t * 1.7 + 1.0) * 1.4
		_bomb.rotation += _spin * delta
		if _bomb.position.y <= GROUND_Y:
			_impact()
	else:
		_since_boom += delta
		if _since_boom >= AFTER_BOOM:
			set_process(false)
			finished.emit()

	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.4)
		var k := _shake * _shake
		_cam.position = Vector3(
			randf_range(-1.0, 1.0) * k * 2.2,
			2.0 + randf_range(-1.0, 1.0) * k * 2.2,
			27.0
		)
		_flash.light_energy = maxf(0.0, _flash.light_energy - delta * 90.0)
	else:
		_cam.position = Vector3(0.0, 2.0, 27.0)


func _impact() -> void:
	_falling = false
	_bomb.visible = false
	if _pfp != null:
		_pfp.visible = false
	_shake = 1.0
	_flash.light_energy = 14.0
	_fire.emitting = true
	_smoke.emitting = true
	if not Sfx.muted:
		_boom.play()
	flashed.emit()
