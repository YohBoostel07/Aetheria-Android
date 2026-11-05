extends CharacterBody3D

signal defeated

@export var max_health: int = 60
@export var move_speed: float = 2.4
@export var attack_damage: int = 12
@export var attack_range: float = 1.55
@export var attack_interval: float = 1.25
@export var player_path: NodePath

var health: int
var attack_timer := 0.0
var hit_flash := 0.0
var player: CharacterBody3D
var body_mesh: MeshInstance3D
var eye_material: StandardMaterial3D
var body_material: StandardMaterial3D
var health_label: Label3D
var walk_phase := 0.0
var is_defeated := false

func _ready() -> void:
    add_to_group("enemies")
    health = max_health
    player = get_node_or_null(player_path) as CharacterBody3D
    _build_creature()

func _physics_process(delta: float) -> void:
    if is_defeated:
        return
    if player == null or not is_instance_valid(player) or int(player.get("health")) <= 0:
        velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
        move_and_slide()
        return
    attack_timer = maxf(0.0, attack_timer - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    body_material.albedo_color = Color(1.0, 0.55, 0.48) if hit_flash > 0.0 else Color(0.30, 0.16, 0.43)
    var to_player := player.global_position - global_position
    to_player.y = 0.0
    var distance := to_player.length()
    if distance > attack_range:
        var direction := to_player.normalized()
        velocity.x = move_toward(velocity.x, direction.x * move_speed, 9.0 * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, 9.0 * delta)
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 8.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
        if attack_timer <= 0.0:
            attack_timer = attack_interval
            player.call("take_damage", attack_damage)
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    walk_phase += delta * (5.0 if distance > attack_range else 2.0)
    body_mesh.position.y = 0.88 + absf(sin(walk_phase)) * 0.06 * (1.0 if distance > attack_range else 0.0)

func take_damage(amount: int) -> void:
    if is_defeated or amount <= 0:
        return
    health = maxi(0, health - amount)
    if health_label != null:
        health_label.text = "Sombrio  %d/%d" % [health, max_health]
    hit_flash = 0.16
    if health <= 0:
        is_defeated = true
        defeated.emit()
        queue_free()

func _build_creature() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.43
    capsule.height = 1.75
    collision.shape = capsule
    collision.position.y = 0.88
    add_child(collision)
    var obsidian := StandardMaterial3D.new()
    obsidian.albedo_color = Color(0.045, 0.035, 0.075)
    obsidian.roughness = 0.42
    obsidian.metallic = 0.28
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.105, 0.065, 0.16)
    body_material.roughness = 0.82
    body_mesh = MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = 0.40
    body.height = 1.55
    body.radial_segments = 16
    body_mesh.mesh = body
    body_mesh.position = Vector3(0, 0.92, 0.02)
    body_mesh.scale = Vector3(1.12, 1.0, 0.78)
    body_mesh.material_override = body_material
    add_child(body_mesh)
    _sphere("Hunched shoulder mass", Vector3(0, 1.42, 0.04), 0.48, Color(0.075, 0.045, 0.12))
    _sphere("Skull", Vector3(0, 1.78, -0.12), 0.34, Color(0.12, 0.075, 0.18))
    _sphere("Lower jaw", Vector3(0, 1.54, -0.34), 0.22, Color(0.035, 0.025, 0.055))
    _sphere("Left cheek bone", Vector3(-0.24, 1.66, -0.27), 0.14, Color(0.20, 0.13, 0.25))
    _sphere("Right cheek bone", Vector3(0.24, 1.66, -0.27), 0.14, Color(0.20, 0.13, 0.25))
    var eye_glow := StandardMaterial3D.new()
    eye_glow.albedo_color = Color(1.0, 0.055, 0.025)
    eye_glow.emission_enabled = true
    eye_glow.emission = Color(1.0, 0.025, 0.008)
    eye_glow.emission_energy_multiplier = 3.5
    _sphere("Left burning eye", Vector3(-0.13, 1.81, -0.405), 0.052, Color(1.0, 0.045, 0.015))
    _sphere("Right burning eye", Vector3(0.13, 1.81, -0.405), 0.052, Color(1.0, 0.045, 0.015))
    _horn(Vector3(-0.22, 1.98, -0.06), -1.0)
    _horn(Vector3(0.22, 1.98, -0.06), 1.0)
    _limb("Left elongated arm", Vector3(-0.48, 1.05, -0.02), Vector3(0.15, 0.82, 0.15))
    _limb("Right elongated arm", Vector3(0.48, 1.05, -0.02), Vector3(0.15, 0.82, 0.15))
    _limb("Left lower leg", Vector3(-0.20, 0.32, 0.03), Vector3(0.17, 0.58, 0.17))
    _limb("Right lower leg", Vector3(0.20, 0.32, 0.03), Vector3(0.17, 0.58, 0.17))
    for side in [-1.0, 1.0]:
        _sphere("Shoulder carapace", Vector3(side * 0.48, 1.43, -0.015), 0.24, Color(0.045, 0.035, 0.075))
        _sphere("Elbow bone", Vector3(side * 0.53, 0.77, -0.03), 0.16, Color(0.24, 0.16, 0.27))
        _sphere("Clawed hand", Vector3(side * 0.55, 0.49, -0.12), 0.16, Color(0.055, 0.035, 0.075))
        for claw_index in range(3):
            var claw := MeshInstance3D.new()
            var claw_mesh := CylinderMesh.new()
            claw_mesh.top_radius = 0.004
            claw_mesh.bottom_radius = 0.052
            claw_mesh.height = 0.28
            claw_mesh.radial_segments = 6
            claw.mesh = claw_mesh
            claw.position = Vector3(side * (0.55 + float(claw_index - 1) * 0.10), 0.32, -0.20)
            claw.rotation.x = -0.32
            claw.rotation.z = side * -0.16
            claw.material_override = obsidian
            add_child(claw)
        for spike_index in range(3):
            var spike := MeshInstance3D.new()
            var spike_mesh := CylinderMesh.new()
            spike_mesh.top_radius = 0.004
            spike_mesh.bottom_radius = 0.095 - float(spike_index) * 0.012
            spike_mesh.height = 0.38 + float(spike_index) * 0.08
            spike_mesh.radial_segments = 6
            spike.mesh = spike_mesh
            spike.position = Vector3(side * (0.32 + float(spike_index) * 0.13), 1.65, 0.04)
            spike.rotation.z = side * -0.65
            spike.material_override = obsidian
            add_child(spike)
    for rib_index in range(5):
        var rib_y := 1.24 - float(rib_index) * 0.16
        for side in [-1.0, 1.0]:
            _sphere("Exposed rib", Vector3(side * (0.22 - float(rib_index) * 0.012), rib_y, -0.285), 0.12, Color(0.31, 0.25, 0.34))
    var core := MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.12
    core_mesh.height = 0.24
    core.mesh = core_mesh
    core.position = Vector3(0, 1.16, -0.34)
    var core_mat := StandardMaterial3D.new()
    core_mat.albedo_color = Color(0.9, 0.035, 0.015)
    core_mat.emission_enabled = true
    core_mat.emission = Color(0.9, 0.025, 0.008)
    core_mat.emission_energy_multiplier = 2.4
    core.material_override = core_mat
    add_child(core)
    health_label = Label3D.new()
    health_label.text = "SOMBRIO  %d/%d" % [health, max_health]
    health_label.position = Vector3(0, 2.48, 0)
    health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    health_label.font_size = 30
    health_label.outline_size = 7
    health_label.modulate = Color(1.0, 0.72, 0.68)
    add_child(health_label)
func _sphere(part_name: String, part_position: Vector3, radius: float, color: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = part_name
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh_instance.mesh = sphere
    mesh_instance.position = part_position
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.75
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _horn(part_position: Vector3, side: float) -> void:
    var mesh_instance := MeshInstance3D.new()
    var cone := CylinderMesh.new()
    cone.top_radius = 0.015
    cone.bottom_radius = 0.09
    cone.height = 0.34
    mesh_instance.mesh = cone
    mesh_instance.position = part_position + Vector3(side * 0.08, 0.13, 0)
    mesh_instance.rotation.z = side * -0.42
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.09, 0.13)
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _limb(part_name: String, part_position: Vector3, dimensions: Vector3) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = part_name
    var mesh := CapsuleMesh.new()
    mesh.radius = dimensions.x
    mesh.height = dimensions.y
    mesh_instance.mesh = mesh
    mesh_instance.position = part_position
    mesh_instance.material_override = body_material
    add_child(mesh_instance)
