extends CharacterBody3D

signal defeated

@export var max_health: int = 60
@export var move_speed: float = 3.0
@export var attack_damage: int = 12
@export var attack_range: float = 1.55
@export var attack_interval: float = 1.25
@export var player_path: NodePath

const SOMBRIO_MODEL_PATH := "res://assets/realistic/characters/horror_monster_rigged.glb"
# The source GLB faces +Z; Godot's CharacterBody3D forward convention is -Z.
const MODEL_FORWARD_CORRECTION := PI

var health: int
var attack_timer := 0.0
var hit_flash := 0.0
var player: CharacterBody3D
var model_root: Node3D
var model_materials: Array[BaseMaterial3D] = []
var health_label: Label3D
var walk_phase := 0.0
var is_defeated := false
var is_walking := false
var hit_particles: CPUParticles3D
var aura_light: OmniLight3D
var animation_player: AnimationPlayer
var walk_animation_name := ""
var idle_animation_name := ""
var attack_animation_name := ""
var attack_animation_time := 0.0

func _ready() -> void:
    add_to_group("enemies")
    health = max_health
    player = get_node_or_null(player_path) as CharacterBody3D
    _build_creature()

func _physics_process(delta: float) -> void:
    if is_defeated:
        return
    attack_animation_time = maxf(0.0, attack_animation_time - delta)

    if player == null or not is_instance_valid(player) or int(player.get("health")) <= 0:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
        is_walking = false
        _play_enemy_animation(idle_animation_name)
        _update_locomotion(delta)
        if not is_on_floor():
            velocity.y -= 9.8 * delta
        else:
            velocity.y = 0.0
        move_and_slide()
        return

    attack_timer = maxf(0.0, attack_timer - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    _update_hit_flash()
    if aura_light != null:
        aura_light.light_energy = 1.0 if hit_flash > 0.0 else 0.16

    var to_player := player.global_position - global_position
    to_player.y = 0.0
    var distance := to_player.length()

    if distance > attack_range:
        var direction := to_player.normalized()
        velocity.x = move_toward(velocity.x, direction.x * move_speed, 14.0 * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, 14.0 * delta)
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 12.0 * delta)
        is_walking = Vector2(velocity.x, velocity.z).length() > 0.18
        _play_enemy_animation(walk_animation_name if is_walking else idle_animation_name)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
        is_walking = false
        if attack_timer <= 0.0:
            attack_timer = attack_interval
            attack_animation_time = 0.55
            _play_enemy_animation(attack_animation_name)
            player.call("take_damage", attack_damage)
        elif attack_animation_time > 0.0:
            _play_enemy_animation(attack_animation_name)
        else:
            _play_enemy_animation(idle_animation_name)

    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0

    move_and_slide()
    _update_locomotion(delta)

func _update_locomotion(delta: float) -> void:
    if model_root == null:
        return

    if is_walking:
        walk_phase += delta * 8.0
        # Keep the feet planted: no vertical bobbing. This is only a restrained
        # subtle weight shift layered over the skeletal walk clip.
        model_root.rotation.x = lerpf(model_root.rotation.x, -0.045, 7.0 * delta)
        model_root.rotation.z = lerpf(model_root.rotation.z, sin(walk_phase) * 0.035, 9.0 * delta)
    else:
        model_root.rotation.x = lerpf(model_root.rotation.x, 0.0, 8.0 * delta)
        model_root.rotation.z = lerpf(model_root.rotation.z, 0.0, 8.0 * delta)
    model_root.position.y = 0.0

func _update_hit_flash() -> void:
    for material in model_materials:
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
    if hit_particles != null:
        hit_particles.emitting = false
        hit_particles.restart()
        hit_particles.emitting = true
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
    model_root.rotation.y = MODEL_FORWARD_CORRECTION
    add_child(model_root)

    var imported := packed.instantiate() as Node3D
    if imported == null:
        push_error("O GLB do Sombrio não instanciou um Node3D.")
        return
    model_root.add_child(imported)
    imported.position = Vector3.ZERO
    imported.scale = Vector3.ONE * 0.96
    _collect_model_materials(imported)

    aura_light = OmniLight3D.new()
    aura_light.name = "SombrioCorruptedAura"
    aura_light.position = Vector3(0.0, 1.05, 0.0)
    aura_light.light_color = Color(0.36, 0.025, 0.018)
    aura_light.light_energy = 0.16
    aura_light.omni_range = 2.8
    add_child(aura_light)

    hit_particles = CPUParticles3D.new()
    hit_particles.name = "SombrioImpactSparks"
    var impact_mesh := QuadMesh.new()
    impact_mesh.size = Vector2(0.06, 0.06)
    var impact_material := StandardMaterial3D.new()
    impact_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    impact_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    impact_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    impact_material.albedo_color = Color(0.9, 0.07, 0.025, 0.95)
    impact_material.emission_enabled = true
    impact_material.emission = Color(0.8, 0.025, 0.008)
    impact_material.emission_energy_multiplier = 1.8
    impact_mesh.material = impact_material
    hit_particles.mesh = impact_mesh
    hit_particles.position = Vector3(0.0, 1.0, 0.0)
    hit_particles.amount = 16
    hit_particles.lifetime = 0.38
    hit_particles.one_shot = true
    hit_particles.emitting = false
    hit_particles.direction = Vector3(0.0, 1.0, 0.0)
    hit_particles.spread = 76.0
    hit_particles.initial_velocity_min = 0.8
    hit_particles.initial_velocity_max = 2.0
    hit_particles.gravity = Vector3(0.0, -3.5, 0.0)
    hit_particles.scale_amount_min = 0.018
    hit_particles.scale_amount_max = 0.055
    hit_particles.color = Color(0.85, 0.055, 0.025, 0.95)
    add_child(hit_particles)

    # The CI rigging pass embeds a real skeletal Walk clip in this GLB.
    animation_player = imported.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if animation_player != null:
        for animation_name in animation_player.get_animation_list():
            print("Aetheria Sombrio animation: ", animation_name)
            var clip := animation_player.get_animation(animation_name)
            var key := String(animation_name).to_lower()
            if "walk" in key:
                walk_animation_name = String(animation_name)
                clip.loop_mode = Animation.LOOP_LINEAR
            elif "idle" in key:
                idle_animation_name = String(animation_name)
                clip.loop_mode = Animation.LOOP_LINEAR
            elif "attack" in key:
                attack_animation_name = String(animation_name)
                clip.loop_mode = Animation.LOOP_NONE
        if idle_animation_name != "":
            animation_player.play(idle_animation_name)
        elif walk_animation_name != "":
            animation_player.play(walk_animation_name)
        else:
            push_warning("Sombrio rigged GLB imported without locomotion clips.")
    else:
        push_warning("Sombrio rigged GLB imported without an AnimationPlayer.")

    health_label = Label3D.new()
    health_label.text = "SOMBRIO  %d/%d" % [health, max_health]
    health_label.position = Vector3(0, 2.55, 0)
    health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    health_label.font_size = 30
    health_label.outline_size = 7
    health_label.modulate = Color(1.0, 0.72, 0.68)
    add_child(health_label)

func _play_enemy_animation(animation_name: String) -> void:
    if animation_player == null or animation_name == "":
        return
    if animation_player.current_animation != animation_name or not animation_player.is_playing():
        animation_player.play(animation_name, 0.12)

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
