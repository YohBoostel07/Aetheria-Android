extends Node3D

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var attack_time := 0.0
var walk_phase := 0.0
var tunic_material: StandardMaterial3D
var dark_cloth: StandardMaterial3D
var cape_material: StandardMaterial3D
var leather_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var blue_eye_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var emblem_material: StandardMaterial3D

func _ready() -> void:
    _create_materials()
    _build_character()

func animate_character(delta: float, horizontal_speed: float, airborne: bool) -> void:
    var weight := clampf(horizontal_speed / 5.8, 0.0, 1.0)
    walk_phase += delta * (5.0 + horizontal_speed * 1.8)
    var swing := sin(walk_phase) * 0.72 * weight
    left_leg.rotation.x = swing
    right_leg.rotation.x = -swing
    if airborne:
        left_leg.rotation.x = -0.35
        right_leg.rotation.x = 0.35
        left_arm.rotation.x = -0.55
    else:
        left_arm.rotation.x = -swing * 0.65
    attack_time = maxf(0.0, attack_time - delta)
    var attack_pose := 0.0
    if attack_time > 0.0:
        attack_pose = sin((1.0 - attack_time / 0.32) * PI) * 1.65
    right_arm.rotation.x = -swing * 0.65 - attack_pose

func play_attack() -> void:
    attack_time = 0.32

func _create_materials() -> void:
    tunic_material = _material(Color(0.035, 0.085, 0.19), 0.78)
    dark_cloth = _material(Color(0.018, 0.027, 0.055), 0.9)
    cape_material = _material(Color(0.035, 0.16, 0.42), 0.78)
    leather_material = _material(Color(0.16, 0.075, 0.038), 0.92)
    skin_material = _material(Color(0.78, 0.52, 0.36), 0.88)
    hair_material = _material(Color(0.012, 0.016, 0.028), 0.72)
    blue_eye_material = _material(Color(0.08, 0.55, 1.0), 0.28)
    blue_eye_material.emission_enabled = true
    blue_eye_material.emission = Color(0.015, 0.12, 0.45)
    metal_material = _material(Color(0.67, 0.78, 0.91), 0.25, 0.78)
    gold_material = _material(Color(0.72, 0.48, 0.15), 0.3, 0.55)
    emblem_material = _material(Color(0.92, 0.96, 1.0), 0.35, 0.18)

func _material(color: Color, roughness_value: float = 0.82, metallic_value: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    material.metallic = metallic_value
    return material

func _build_character() -> void:
    # Tailored dark-blue tunic with layered chest and waist details.
    _capsule_part("Tunic", Vector3(0, 0.06, 0), 0.34, 0.78, tunic_material)
    _box_part("Chest panel", Vector3(0, 0.12, -0.285), Vector3(0.39, 0.43, 0.045), dark_cloth)
    _box_part("Center blue trim", Vector3(0, 0.12, -0.313), Vector3(0.045, 0.42, 0.018), cape_material)
    _capsule_part("Neck", Vector3(0, 0.53, 0), 0.12, 0.22, skin_material)
    _sphere_part("Face", Vector3(0, 0.79, -0.005), 0.235, skin_material, Vector3(0.94, 1.08, 0.9))
    _sphere_part("Hair cap", Vector3(0, 0.94, 0.025), 0.235, hair_material, Vector3(1.08, 0.72, 1.0))
    _box_part("Front fringe", Vector3(0, 0.84, -0.185), Vector3(0.35, 0.12, 0.11), hair_material)
    # Distinct swept spikes create the established black spiky hairstyle.
    _hair_spike(Vector3(-0.15, 0.99, -0.015), Vector3(-0.16, 0.34, -0.05), 0.105)
    _hair_spike(Vector3(-0.04, 1.02, 0.015), Vector3(-0.04, 0.39, 0.02), 0.11)
    _hair_spike(Vector3(0.08, 1.0, 0.015), Vector3(0.12, 0.34, 0.035), 0.105)
    _hair_spike(Vector3(0.18, 0.96, 0.035), Vector3(0.25, 0.27, 0.09), 0.10)
    _hair_spike(Vector3(-0.21, 0.92, 0.07), Vector3(-0.29, 0.18, 0.16), 0.09)
    _sphere_part("Left eye", Vector3(-0.078, 0.79, -0.211), 0.033, blue_eye_material, Vector3(0.85, 0.72, 0.55))
    _sphere_part("Right eye", Vector3(0.078, 0.79, -0.211), 0.033, blue_eye_material, Vector3(0.85, 0.72, 0.55))
    _box_part("Belt", Vector3(0, -0.27, -0.005), Vector3(0.61, 0.12, 0.41), leather_material)
    _box_part("Buckle", Vector3(0, -0.27, -0.22), Vector3(0.13, 0.13, 0.035), gold_material)
    _box_part("Waist sash", Vector3(0, -0.36, -0.02), Vector3(0.55, 0.09, 0.4), dark_cloth)

    # Cape sits behind the body, with split tails and the white back insignia.
    _box_part("Cape shoulder clasp", Vector3(0, 0.42, 0.19), Vector3(0.42, 0.12, 0.12), gold_material)
    _box_part("Cape upper", Vector3(0, 0.04, 0.245), Vector3(0.67, 0.72, 0.075), cape_material)
    _box_part("Cape left tail", Vector3(-0.17, -0.48, 0.25), Vector3(0.31, 0.48, 0.075), cape_material)
    _box_part("Cape right tail", Vector3(0.17, -0.48, 0.25), Vector3(0.31, 0.48, 0.075), cape_material)
    _box_part("Cape white sigil vertical", Vector3(0, 0.08, 0.292), Vector3(0.075, 0.39, 0.025), emblem_material)
    _box_part("Cape white sigil cross", Vector3(0, 0.12, 0.294), Vector3(0.29, 0.075, 0.025), emblem_material)
    _box_part("Cape white sigil lower", Vector3(0, -0.10, 0.294), Vector3(0.22, 0.065, 0.025), emblem_material)

    left_leg = _pivot("LeftLeg", Vector3(-0.17, -0.34, 0))
    _capsule_child(left_leg, "Dark trousers", 0.145, 0.62, dark_cloth, Vector3(0, -0.25, 0))
    _box_child(left_leg, "Leather shin guard", Vector3(0, -0.34, -0.125), Vector3(0.22, 0.28, 0.08), leather_material)
    _box_child(left_leg, "Boot", Vector3(0, -0.55, -0.055), Vector3(0.29, 0.19, 0.42), dark_cloth)
    _box_child(left_leg, "Boot sole", Vector3(0, -0.64, -0.07), Vector3(0.30, 0.055, 0.43), leather_material)
    right_leg = _pivot("RightLeg", Vector3(0.17, -0.34, 0))
    _capsule_child(right_leg, "Dark trousers", 0.145, 0.62, dark_cloth, Vector3(0, -0.25, 0))
    _box_child(right_leg, "Leather shin guard", Vector3(0, -0.34, -0.125), Vector3(0.22, 0.28, 0.08), leather_material)
    _box_child(right_leg, "Boot", Vector3(0, -0.55, -0.055), Vector3(0.29, 0.19, 0.42), dark_cloth)
    _box_child(right_leg, "Boot sole", Vector3(0, -0.64, -0.07), Vector3(0.30, 0.055, 0.43), leather_material)

    left_arm = _pivot("LeftArm", Vector3(-0.39, 0.37, 0))
    _capsule_child(left_arm, "Blue sleeve", 0.14, 0.60, tunic_material, Vector3(0, -0.24, 0))
    _sphere_child(left_arm, "Shoulder armor", Vector3(0, -0.06, 0), 0.17, metal_material)
    _capsule_child(left_arm, "Leather forearm guard", 0.105, 0.30, leather_material, Vector3(0, -0.36, -0.015))
    _sphere_child(left_arm, "Glove", Vector3(0, -0.51, -0.015), 0.12, dark_cloth)
    right_arm = _pivot("RightArm", Vector3(0.39, 0.37, 0))
    _capsule_child(right_arm, "Blue sleeve", 0.14, 0.60, tunic_material, Vector3(0, -0.24, 0))
    _sphere_child(right_arm, "Shoulder armor", Vector3(0, -0.06, 0), 0.17, metal_material)
    _capsule_child(right_arm, "Leather forearm guard", 0.105, 0.30, leather_material, Vector3(0, -0.36, -0.015))
    _sphere_child(right_arm, "Glove", Vector3(0, -0.51, -0.015), 0.12, dark_cloth)
    _create_sword(right_arm)

func _hair_spike(base: Vector3, tip_offset: Vector3, radius_value: float) -> void:
    var spike := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.008
    mesh.bottom_radius = radius_value
    mesh.height = tip_offset.length()
    mesh.radial_segments = 7
    spike.mesh = mesh
    spike.position = base + tip_offset * 0.5
    spike.look_at(spike.position + tip_offset.normalized(), Vector3.UP)
    spike.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    spike.material_override = hair_material
    add_child(spike)

func _pivot(part_name: String, part_position: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = part_name
    pivot.position = part_position
    add_child(pivot)
    return pivot

func _capsule_part(part_name: String, part_position: Vector3, radius_value: float, height_value: float, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius_value
    mesh.height = height_value
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    add_child(part)

func _capsule_child(parent: Node3D, part_name: String, radius_value: float, height_value: float, material: Material, part_position: Vector3) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius_value
    mesh.height = height_value
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    parent.add_child(part)

func _sphere_part(part_name: String, part_position: Vector3, radius_value: float, material: Material, scale_value: Vector3 = Vector3.ONE) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := SphereMesh.new()
    mesh.radius = radius_value
    mesh.height = radius_value * 2.0
    part.mesh = mesh
    part.position = part_position
    part.scale = scale_value
    part.material_override = material
    add_child(part)

func _sphere_child(parent: Node3D, part_name: String, part_position: Vector3, radius_value: float, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := SphereMesh.new()
    mesh.radius = radius_value
    mesh.height = radius_value * 2.0
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    parent.add_child(part)

func _box_part(part_name: String, part_position: Vector3, dimensions: Vector3, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    add_child(part)

func _box_child(parent: Node3D, part_name: String, part_position: Vector3, dimensions: Vector3, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    parent.add_child(part)

func _create_sword(hand: Node3D) -> void:
    _box_child(hand, "Sword blade", Vector3(0, -0.83, -0.08), Vector3(0.075, 0.62, 0.035), metal_material)
    _box_child(hand, "Sword fuller", Vector3(0, -0.82, -0.101), Vector3(0.018, 0.48, 0.008), gold_material)
    _box_child(hand, "Sword guard", Vector3(0, -0.53, -0.08), Vector3(0.30, 0.065, 0.08), gold_material)
    var grip := MeshInstance3D.new()
    grip.name = "Sword grip"
    var grip_mesh := CylinderMesh.new()
    grip_mesh.top_radius = 0.035
    grip_mesh.bottom_radius = 0.035
    grip_mesh.height = 0.19
    grip.mesh = grip_mesh
    grip.position = Vector3(0, -0.43, -0.08)
    grip.material_override = leather_material
    hand.add_child(grip)
