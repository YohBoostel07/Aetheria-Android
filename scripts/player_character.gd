extends Node3D

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var attack_time := 0.0
var walk_phase := 0.0
var tunic_material: StandardMaterial3D
var leather_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var gold_material: StandardMaterial3D

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
    tunic_material = _material(Color(0.12, 0.28, 0.58))
    leather_material = _material(Color(0.25, 0.13, 0.075))
    skin_material = _material(Color(0.82, 0.58, 0.39))
    dark_material = _material(Color(0.075, 0.055, 0.045))
    metal_material = _material(Color(0.72, 0.79, 0.86), 0.28, 0.72)
    gold_material = _material(Color(0.88, 0.61, 0.19), 0.32, 0.45)

func _material(color: Color, roughness_value: float = 0.82, metallic_value: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    material.metallic = metallic_value
    return material

func _build_character() -> void:
    _capsule_part("Tunic", Vector3(0, 0.08, 0), 0.34, 0.76, tunic_material)
    _capsule_part("Neck", Vector3(0, 0.55, 0), 0.12, 0.22, skin_material)
    _sphere_part("Head", Vector3(0, 0.78, 0), 0.235, skin_material)
    _sphere_part("Hair", Vector3(0, 0.91, 0.035), 0.225, dark_material)
    _box_part("Hair fringe", Vector3(0, 0.82, -0.17), Vector3(0.34, 0.11, 0.13), dark_material)
    _sphere_part("Eye L", Vector3(-0.078, 0.79, -0.205), 0.025, dark_material, Vector3.ONE * 0.75)
    _sphere_part("Eye R", Vector3(0.078, 0.79, -0.205), 0.025, dark_material, Vector3.ONE * 0.75)
    _box_part("Belt", Vector3(0, -0.25, -0.005), Vector3(0.58, 0.10, 0.39), leather_material)
    _box_part("Buckle", Vector3(0, -0.25, -0.21), Vector3(0.12, 0.12, 0.035), gold_material)

    left_leg = _pivot("LeftLeg", Vector3(-0.17, -0.34, 0))
    _capsule_child(left_leg, "Leg", 0.145, 0.62, leather_material, Vector3(0, -0.25, 0))
    _box_child(left_leg, "Boot", Vector3(0, -0.55, -0.055), Vector3(0.27, 0.17, 0.39), dark_material)
    right_leg = _pivot("RightLeg", Vector3(0.17, -0.34, 0))
    _capsule_child(right_leg, "Leg", 0.145, 0.62, leather_material, Vector3(0, -0.25, 0))
    _box_child(right_leg, "Boot", Vector3(0, -0.55, -0.055), Vector3(0.27, 0.17, 0.39), dark_material)

    left_arm = _pivot("LeftArm", Vector3(-0.39, 0.37, 0))
    _capsule_child(left_arm, "Sleeve", 0.135, 0.62, tunic_material, Vector3(0, -0.24, 0))
    _sphere_child(left_arm, "Hand", Vector3(0, -0.51, 0), 0.12, skin_material)
    right_arm = _pivot("RightArm", Vector3(0.39, 0.37, 0))
    _capsule_child(right_arm, "Sleeve", 0.135, 0.62, tunic_material, Vector3(0, -0.24, 0))
    _sphere_child(right_arm, "Hand", Vector3(0, -0.51, 0), 0.12, skin_material)
    _create_sword(right_arm)

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
    _box_child(hand, "Sword blade", Vector3(0, -0.83, -0.08), Vector3(0.075, 0.55, 0.035), metal_material)
    _box_child(hand, "Sword guard", Vector3(0, -0.53, -0.08), Vector3(0.28, 0.055, 0.07), gold_material)
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
