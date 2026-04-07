extends Node3D
class_name StarField

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77142

	# Three depth layers — deeper = more stars, smaller, slower apparent motion
	_make_layer(rng, -65.0, 600, 0.055, 1400.0, Color(0.78, 0.84, 1.00, 1.0), 0.9)
	_make_layer(rng, -22.0, 220, 0.095, 900.0,  Color(0.92, 0.94, 1.00, 1.0), 1.1)
	_make_layer(rng,  -5.0,  80, 0.160, 500.0,  Color(1.00, 1.00, 1.00, 1.0), 1.4)

func _make_layer(
		rng: RandomNumberGenerator,
		y: float,
		count: int,
		radius: float,
		spread: float,
		color: Color,
		emission_energy: float
) -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = radius
	star_mesh.height = radius * 2.0
	star_mesh.radial_segments = 4
	star_mesh.rings = 2

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission_energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mesh.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = star_mesh
	mm.instance_count = count

	for i in range(count):
		var x := rng.randf_range(-spread * 0.5, spread * 0.5)
		var z := rng.randf_range(-spread * 0.5, spread * 0.5)
		# Slight scale variation per star for organic feel
		var s := rng.randf_range(0.7, 1.4)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(x, y, z)))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
