extends CharacterBody3D

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

func _ready() -> void:
    add_to_group("enemies")
    health = max_health
    player = get_node_or_null(player_path) as CharacterBody3D
    _build_creature()

func _physics_process(delta: float) -> void:
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
    health = maxi(0, health - amount)
    if health_label != null:
        health_label.text = "Sombrio  %d/%d" % [health, max_health]
    hit_flash = 0.16
    if health <= 0:
        queue_free()

func _build_creature() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.43
    capsule.height = 1.75
    collision.shape = capsule
    collision.position.y = 0.88
    add_child(collision)

    body_mesh = MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = 0.42
    body.height = 1.55
    body_mesh.mesh = body
    body_mesh.position.y = 0.88
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.30, 0.16, 0.43)
    body_material.roughness = 0.88
    body_mesh.material_override = body_material
    add_child(body_mesh)

    _sphere("Head", Vector3(0, 1.72, -0.04), 0.34, Color(0.38, 0.22, 0.50))
    _sphere("Jaw", Vector3(0, 1.52, -0.22), 0.22, Color(0.23, 0.12, 0.32))
    _sphere("Left eye", Vector3(-0.13, 1.78, -0.34), 0.055, Color(1.0, 0.12, 0.08))
    _sphere("Right eye", Vector3(0.13, 1.78, -0.34), 0.055, Color(1.0, 0.12, 0.08))
    _horn(Vector3(-0.22, 2.0, 0.0), -1.0)
    _horn(Vector3(0.22, 2.0, 0.0), 1.0)
    _limb("Left arm", Vector3(-0.43, 1.12, 0), Vector3(0.13, 0.48, 0.13))
    _limb("Right arm", Vector3(0.43, 1.12, 0), Vector3(0.13, 0.48, 0.13))

    health_label = Label3D.new()
    health_label.text = "Sombrio  %d/%d" % [health, max_health]
    health_label.position = Vector3(0, 2.35, 0)
    health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    health_label.font_size = 32
    health_label.outline_size = 6
    health_label.modulate = Color(1.0, 0.82, 0.82)
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
