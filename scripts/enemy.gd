extends CharacterBody3D

signal defeated

@export var max_health: int = 60
@export var move_speed: float = 2.4
@export var attack_damage: int = 12
@export var attack_range: float = 1.55
@export var attack_interval: float = 1.25
@export var player_path: NodePath

const SOMBRIO_MODEL_PATH := "res://assets/realistic/characters/horror_monster_light.glb"

var health: int
var attack_timer := 0.0
var hit_flash := 0.0
var player: CharacterBody3D
var model_root: Node3D
var model_materials: Array[BaseMaterial3D] = []
var health_label: Label3D
var walk_phase := 0.0
var is_defeated := false
var original_material_colors: Array[Color] = []

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
    _update_hit_flash()
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
    if model_root != null:
        # The imported sculpt remains intact; subtle whole-body motion avoids
        # deforming or rebuilding the high-detail mesh from primitive parts.
        model_root.position.y = 0.03 + absf(sin(walk_phase)) * 0.045
        model_root.rotation.z = sin(walk_phase * 0.5) * 0.018

func _update_hit_flash() -> void:
    for i in range(model_materials.size()):
        var material := model_materials[i]
        if material == null:
            continue
        if hit_flash > 0.0:
            material.emission_enabled = true
            material.emission = Color(0.55, 0.035, 0.02)
            material.emission_energy_multiplier = 0.8
        else:
            material.emission_enabled = false

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
    capsule.radius = 0.40
    capsule.height = 2.15
    collision.shape = capsule
    collision.position.y = 1.05
    add_child(collision)

    var packed := load(SOMBRIO_MODEL_PATH) as PackedScene
    if packed == null:
        push_error("Modelo real do Sombrio não encontrado: " + SOMBRIO_MODEL_PATH)
        return
    model_root = Node3D.new()
    model_root.name = "SombrioHighDetail"
    add_child(model_root)
    var imported := packed.instantiate()
    model_root.add_child(imported)
    # Source asset is authored at 2.2 m tall; preserve its scanned proportions.
    imported.position = Vector3.ZERO
    imported.scale = Vector3.ONE * 0.96
    _collect_model_materials(imported)
    health_label = Label3D.new()
    health_label.text = "SOMBRIO  %d/%d" % [health, max_health]
    health_label.position = Vector3(0, 2.55, 0)
    health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    health_label.font_size = 30
    health_label.outline_size = 7
    health_label.modulate = Color(1.0, 0.72, 0.68)
    add_child(health_label)

func _collect_model_materials(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        var mesh := mesh_instance.mesh
        if mesh != null:
            for surface in range(mesh.get_surface_count()):
                var material := mesh_instance.get_active_material(surface) as BaseMaterial3D
                if material != null and not model_materials.has(material):
                    model_materials.append(material)
    for child in node.get_children():
        _collect_model_materials(child)
