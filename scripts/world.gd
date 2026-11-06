extends Node3D

const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

var rng := RandomNumberGenerator.new()
var bark_material: StandardMaterial3D
var branch_material: StandardMaterial3D
var leaf_materials: Array[StandardMaterial3D] = []
var leaf_light_materials: Array[StandardMaterial3D] = []
var stone_material: StandardMaterial3D
var dark_stone_material: StandardMaterial3D
var path_material: StandardMaterial3D
var crystal_material: StandardMaterial3D
var torch_material: StandardMaterial3D
var quest_label: Label
var quest_detail_label: Label
var enemies_defeated := 0
var quest_complete := false
var experience := 0
var shrine_crystal_light: OmniLight3D
var inventory_label: Label
var pickup_notice_label: Label
var pickups: Array[Dictionary] = []
var torch_lights: Array[OmniLight3D] = []
var torch_flames: Array[MeshInstance3D] = []
var crystal_particles: CPUParticles3D

func _ready() -> void:
    rng.seed = 48291
    _create_materials()
    _create_environment()
    _create_ground()
    _create_ancient_shrine()
    _create_architecture_details()
    _create_torches()
    _create_quest_hud()
    _create_inventory_hud()
    _create_pickups()
    _spawn_enemies()
    _refresh_quest_hud()

func _process(delta: float) -> void:
    _update_pickups(delta)
    var flicker_time := float(Time.get_ticks_msec()) * 0.001
    for i in range(torch_lights.size()):
        var flicker := sin(flicker_time * 8.0 + float(i) * 1.7) * 0.09 + sin(flicker_time * 17.0 + float(i)) * 0.035
        var torch_light := torch_lights[i]
        if is_instance_valid(torch_light):
            torch_light.light_energy = 0.58 + flicker
        if i < torch_flames.size() and is_instance_valid(torch_flames[i]):
            var flame := torch_flames[i]
            flame.scale = Vector3(1.0 + flicker * 0.8, 1.0 + absf(flicker) * 1.2, 1.0 + flicker * 0.6)
    if enemies_defeated >= 3 and not quest_complete:
        var player := get_node_or_null("Player") as Node3D
        if player != null:
            var player_flat := Vector2(player.global_position.x, player.global_position.z)
            var crystal_flat := Vector2(0.0, -35.45)
            if player_flat.distance_to(crystal_flat) <= 4.5:
                _complete_quest()

func _create_materials() -> void:
    bark_material = _material(Color(0.25, 0.14, 0.085), 1.0)
    branch_material = _material(Color(0.19, 0.105, 0.065), 1.0)
    stone_material = _material(Color(0.38, 0.42, 0.46), 0.95)
    dark_stone_material = _material(Color(0.20, 0.24, 0.29), 1.0)
    path_material = _material(Color(0.48, 0.43, 0.34), 1.0)
    crystal_material = _material(Color(0.12, 0.68, 0.92), 0.24, 0.25)
    crystal_material.emission_enabled = true
    crystal_material.emission = Color(0.04, 0.42, 0.85)
    crystal_material.emission_energy_multiplier = 1.8
    torch_material = _material(Color(1.0, 0.36, 0.07), 0.3)
    torch_material.emission_enabled = true
    torch_material.emission = Color(1.0, 0.19, 0.025)
    torch_material.emission_energy_multiplier = 2.2
    leaf_materials = [
        _material(Color(0.055, 0.20, 0.095), 0.96),
        _material(Color(0.075, 0.27, 0.11), 0.96),
        _material(Color(0.12, 0.33, 0.14), 0.94),
        _material(Color(0.18, 0.38, 0.16), 0.94),
        _material(Color(0.23, 0.34, 0.12), 0.96)
    ]
    leaf_light_materials = [
        _material(Color(0.19, 0.39, 0.16), 0.94),
        _material(Color(0.25, 0.43, 0.18), 0.94)
    ]

func _material(color: Color, roughness_value: float = 0.85, metallic_value: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    material.metallic = metallic_value
    return material

func _create_environment() -> void:
    var world_env := Environment.new()
    world_env.background_mode = Environment.BG_SKY
    world_env.sky = Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.035, 0.095, 0.19)
    sky_material.sky_horizon_color = Color(0.62, 0.70, 0.76)
    sky_material.ground_bottom_color = Color(0.12, 0.16, 0.13)
    sky_material.ground_horizon_color = Color(0.42, 0.48, 0.40)
    world_env.sky.sky_material = sky_material
    world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world_env.ambient_light_color = Color(0.63, 0.72, 0.84)
    world_env.ambient_light_energy = 0.72
    world_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.fog_enabled = true
    world_env.fog_light_color = Color(0.55, 0.65, 0.68)
    world_env.fog_density = 0.0055
    world_env.fog_sun_scatter = 0.22
    world_env.fog_aerial_perspective = 0.35
    world_env.glow_enabled = true
    world_env.glow_intensity = 0.38
    world_env.glow_strength = 0.82
    world_env.glow_bloom = 0.08
    world_env.adjustment_enabled = true
    world_env.adjustment_brightness = 1.02
    world_env.adjustment_contrast = 1.08
    world_env.adjustment_saturation = 1.08
    var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
    if sun:
        sun.light_color = Color(0.82, 0.88, 1.0)
        sun.light_energy = 1.12
        sun.light_angular_distance = 0.32
        sun.directional_shadow_max_distance = 68.0
        sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
        sun.directional_shadow_blend_splits = true

    var node := get_node_or_null("WorldEnvironment") as WorldEnvironment
    if node:
        node.environment = world_env

func _create_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    add_child(ground)

    var mesh_instance := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(180, 180)
    mesh_instance.mesh = plane

    # Poly Haven CC0 scanned forest-floor material: albedo, normal and roughness.
    var forest_floor := StandardMaterial3D.new()
    forest_floor.albedo_texture = load("res://assets/realistic/materials/forest_floor_albedo.jpg") as Texture2D
    forest_floor.normal_enabled = true
    forest_floor.normal_texture = load("res://assets/realistic/materials/forest_floor_normal.jpg") as Texture2D
    forest_floor.normal_scale = 0.9
    forest_floor.roughness = 1.0
    forest_floor.roughness_texture = load("res://assets/realistic/materials/forest_floor_roughness.jpg") as Texture2D
    forest_floor.uv1_scale = Vector3(28.0, 28.0, 1.0)
    mesh_instance.material_override = forest_floor
    ground.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(180, 0.3, 180)
    collision.shape = shape
    collision.position.y = -0.15
    ground.add_child(collision)

func _create_path() -> void:
    for i in range(25):
        var stone := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(rng.randf_range(1.5, 2.5), 0.10, rng.randf_range(1.0, 1.7))
        stone.mesh = mesh
        stone.position = Vector3(rng.randf_range(-0.55, 0.55), 0.035, 5.0 - float(i) * 1.75)
        stone.rotation.y = rng.randf_range(-0.18, 0.18)
        stone.material_override = path_material if i % 3 != 0 else stone_material
        add_child(stone)
    for i in range(22):
        var pebble := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.12, 0.24)
        mesh.height = mesh.radius * 0.55
        pebble.mesh = mesh
        pebble.scale = Vector3(1.3, 0.65, 0.9)
        pebble.position = Vector3(rng.randf_range(-2.3, 2.3), 0.06, rng.randf_range(-34, 7))
        pebble.material_override = stone_material
        add_child(pebble)

func _create_forest() -> void:
    for i in range(58):
        var position := Vector3(rng.randf_range(-52, 52), 0, rng.randf_range(-52, 52))
        var near_path := absf(position.x) < 4.2 and position.z < 8.0 and position.z > -39.0
        var near_spawn := position.distance_to(Vector3(0, 0, 4)) < 9.0
        var near_shrine := position.distance_to(Vector3(0, 0, -34)) < 9.0
        if near_path or near_spawn or near_shrine:
            continue
        _create_tree(position, rng.randf_range(0.82, 1.35))
    for i in range(34):
        var grass := MeshInstance3D.new()
        var blade := CylinderMesh.new()
        blade.top_radius = 0.015
        blade.bottom_radius = 0.055
        blade.height = rng.randf_range(0.28, 0.55)
        blade.radial_segments = 5
        grass.mesh = blade
        grass.position = Vector3(rng.randf_range(-42, 42), blade.height * 0.5, rng.randf_range(-42, 42))
        grass.rotation.z = rng.randf_range(-0.25, 0.25)
        grass.material_override = leaf_materials[rng.randi_range(0, leaf_materials.size() - 1)]
        add_child(grass)

func _create_tree(tree_position: Vector3, scale_value: float) -> void:
    var tree := Node3D.new()
    tree.position = tree_position
    tree.scale = Vector3.ONE * scale_value
    add_child(tree)

    var trunk_height := rng.randf_range(3.5, 4.5)
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = rng.randf_range(0.13, 0.19)
    trunk_mesh.bottom_radius = rng.randf_range(0.31, 0.39)
    trunk_mesh.height = trunk_height
    trunk.mesh = trunk_mesh
    trunk.position.y = trunk_height * 0.5
    trunk.rotation.z = rng.randf_range(-0.035, 0.035)
    trunk.material_override = bark_material
    tree.add_child(trunk)

    # Raised bark ridges make the trunk less like a smooth primitive.
    for ridge_index in range(4):
        var ridge := MeshInstance3D.new()
        var ridge_mesh := CylinderMesh.new()
        ridge_mesh.top_radius = 0.025
        ridge_mesh.bottom_radius = 0.055
        ridge_mesh.height = trunk_height * rng.randf_range(0.55, 0.88)
        ridge.mesh = ridge_mesh
        var angle := TAU * float(ridge_index) / 4.0
        ridge.position = Vector3(cos(angle) * 0.19, ridge_mesh.height * 0.5, sin(angle) * 0.19)
        ridge.rotation.z = rng.randf_range(-0.04, 0.04)
        ridge.material_override = branch_material
        tree.add_child(ridge)

    # Several thick, tapered boughs visibly emerge from the trunk.
    for branch_index in range(6):
        var angle := TAU * float(branch_index) / 6.0 + rng.randf_range(-0.22, 0.22)
        var start_height := rng.randf_range(1.65, 2.85)
        var length := rng.randf_range(1.25, 2.0)
        var rise := rng.randf_range(0.65, 1.25)
        var direction := Vector3(cos(angle) * length, rise, sin(angle) * length)
        _create_branch(tree, Vector3(0, start_height, 0), direction, rng.randf_range(0.10, 0.15))

    # A layered, irregular crown made of many overlapping leaf masses.
    var crown_center := Vector3(0, trunk_height + 0.15, 0)
    for cluster_index in range(15):
        var angle := rng.randf_range(0.0, TAU)
        var ring := rng.randf_range(0.25, 1.35)
        var cluster := MeshInstance3D.new()
        var foliage := SphereMesh.new()
        foliage.radius = rng.randf_range(0.58, 0.88)
        foliage.height = rng.randf_range(1.05, 1.65)
        foliage.radial_segments = 10
        foliage.rings = 6
        cluster.mesh = foliage
        cluster.position = crown_center + Vector3(cos(angle) * ring, rng.randf_range(-0.45, 1.15), sin(angle) * ring)
        cluster.scale = Vector3(rng.randf_range(0.9, 1.35), rng.randf_range(0.75, 1.1), rng.randf_range(0.9, 1.3))
        cluster.material_override = leaf_materials[rng.randi_range(0, leaf_materials.size() - 1)]
        tree.add_child(cluster)

    # Smaller brighter leaf clusters break up the silhouette and add depth.
    for leaf_index in range(10):
        var angle := rng.randf_range(0.0, TAU)
        var leaf := MeshInstance3D.new()
        var leaf_mesh := SphereMesh.new()
        leaf_mesh.radius = rng.randf_range(0.18, 0.31)
        leaf_mesh.height = rng.randf_range(0.28, 0.48)
        leaf_mesh.radial_segments = 8
        leaf_mesh.rings = 5
        leaf.mesh = leaf_mesh
        leaf.position = crown_center + Vector3(cos(angle) * rng.randf_range(0.55, 1.55), rng.randf_range(-0.35, 1.4), sin(angle) * rng.randf_range(0.55, 1.55))
        leaf.rotation = Vector3(rng.randf_range(-0.5, 0.5), angle, rng.randf_range(-0.5, 0.5))
        leaf.material_override = leaf_light_materials[rng.randi_range(0, leaf_light_materials.size() - 1)]
        tree.add_child(leaf)

func _create_branch(parent: Node3D, start: Vector3, direction: Vector3, thickness: float) -> void:
    var branch := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = thickness * 0.42
    mesh.bottom_radius = thickness
    mesh.height = direction.length()
    mesh.radial_segments = 7
    branch.mesh = mesh
    branch.position = start + direction * 0.5
    branch.look_at(branch.position + direction.normalized(), Vector3.UP)
    branch.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    branch.material_override = branch_material
    parent.add_child(branch)

func _create_rock_fields() -> void:
    for i in range(30):
        var rock := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.35, 0.85)
        mesh.height = mesh.radius * 1.5
        rock.mesh = mesh
        rock.scale = Vector3(rng.randf_range(0.9, 1.7), rng.randf_range(0.65, 1.1), rng.randf_range(0.8, 1.4))
        rock.position = Vector3(rng.randf_range(-48, 48), 0.28, rng.randf_range(-48, 48))
        if rock.position.distance_to(Vector3(0, 0, 4)) < 8.0 or (absf(rock.position.x) < 3.0 and rock.position.z < 7.0 and rock.position.z > -38.0):
            rock.queue_free()
            continue
        rock.material_override = stone_material if i % 2 == 0 else dark_stone_material
        add_child(rock)

func _create_ancient_shrine() -> void:
    var shrine := Node3D.new()
    shrine.name = "AncientShrine"
    shrine.position = Vector3(0, 0, -35)
    add_child(shrine)

    # Weathered real-scale masonry and photogrammetry rock replace the stylized ruin kit.
    for side in [-1.0, 1.0]:
        for depth in [-2.0, 0.35, 2.7]:
            _add_architecture_asset(shrine, "res://assets/realistic/nature/dry_stone_wall_section.glb", Vector3(side * 4.6, 0.0, depth), 1.35, PI * 0.5)
            _add_static_box_collision(shrine, Vector3(side * 4.6, 0.82, depth), Vector3(3.62, 1.68, 0.76), PI * 0.5)
        _add_architecture_asset(shrine, "res://assets/realistic/nature/rocky_outcrop.glb", Vector3(side * 6.8, 0.0, -2.2), 0.42, side * 0.35)

    var altar := Node3D.new()
    altar.name = "CrystalAltar"
    altar.position = Vector3(0.0, 0.0, -0.35)
    shrine.add_child(altar)
    _box(altar, "Weathered altar base", Vector3(0, 0.42, 0), Vector3(2.35, 0.84, 1.65), dark_stone_material)
    _box(altar, "Altar capstone", Vector3(0, 0.88, 0), Vector3(2.75, 0.16, 1.92), stone_material)
    _add_static_box_collision(altar, Vector3(0, 0.5, 0), Vector3(2.35, 1.0, 1.65), 0.0)
    _create_crystal(altar, Vector3(0, 1.65, 0), 1.0)
    _create_crystal(shrine, Vector3(-4.5, 0.95, 0.2), 0.55)
    _create_crystal(shrine, Vector3(4.5, 0.95, 0.2), 0.55)

    var title := Label3D.new()
    title.text = "SANTUÁRIO ANTIGO"
    title.position = Vector3(0, 4.4, -2.4)
    title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    title.font_size = 40
    title.outline_size = 8
    title.modulate = Color(0.78, 0.91, 1.0)
    shrine.add_child(title)
    _create_crystal_particles(shrine, Vector3(0, 1.8, -0.35))

func _add_architecture_asset(parent: Node3D, asset_path: String, asset_position: Vector3, scale_value: float, yaw: float) -> void:
    var packed := load(asset_path) as PackedScene
    if packed == null:
        push_warning("Aetheria: asset arquitetônico não carregado: " + asset_path)
        return
    var instance := packed.instantiate() as Node3D
    if instance == null:
        push_warning("Aetheria: asset arquitetônico sem raiz Node3D: " + asset_path)
        return
    instance.position = asset_position
    instance.rotation.y = yaw
    instance.scale = Vector3.ONE * scale_value
    parent.add_child(instance)

func _create_architecture_details() -> void:
    # Photogrammetry stone bridge crossing above the playable trail.
    _add_architecture_asset(self, "res://assets/realistic/architecture/arch_bridge_stone.glb", Vector3(0.0, 0.0, -19.5), 0.22, 0.0)

func _add_static_box_collision(parent: Node3D, local_position: Vector3, dimensions: Vector3, yaw: float) -> void:
    var body := StaticBody3D.new()
    body.position = local_position
    body.rotation.y = yaw
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    parent.add_child(body)

func _create_crystal_particles(parent: Node3D, particle_position: Vector3) -> void:
    crystal_particles = CPUParticles3D.new()
    crystal_particles.name = "SanctuaryArcaneMotes"
    crystal_particles.position = particle_position
    var mote_mesh := SphereMesh.new()
    mote_mesh.radius = 0.035
    mote_mesh.height = 0.07
    mote_mesh.radial_segments = 8
    mote_mesh.rings = 4
    var mote_material := StandardMaterial3D.new()
    mote_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mote_material.albedo_color = Color(0.18, 0.62, 1.0, 0.9)
    mote_material.emission_enabled = true
    mote_material.emission = Color(0.08, 0.32, 1.0)
    mote_material.emission_energy_multiplier = 1.7
    mote_mesh.material = mote_material
    crystal_particles.mesh = mote_mesh
    crystal_particles.amount = 28
    crystal_particles.lifetime = 2.8
    crystal_particles.emitting = true
    crystal_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    crystal_particles.emission_sphere_radius = 1.15
    crystal_particles.direction = Vector3(0.0, 1.0, 0.0)
    crystal_particles.spread = 34.0
    crystal_particles.initial_velocity_min = 0.12
    crystal_particles.initial_velocity_max = 0.42
    crystal_particles.gravity = Vector3(0.0, 0.035, 0.0)
    crystal_particles.scale_amount_min = 0.025
    crystal_particles.scale_amount_max = 0.065
    crystal_particles.color = Color(0.22, 0.72, 1.0, 0.85)
    parent.add_child(crystal_particles)

func _create_crystal(parent: Node3D, crystal_position: Vector3, scale_value: float) -> void:
    var crystal := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.04
    mesh.bottom_radius = 0.42
    mesh.height = 1.35
    mesh.radial_segments = 6
    crystal.mesh = mesh
    crystal.position = crystal_position
    crystal.rotation.z = 0.12
    crystal.scale = Vector3.ONE * scale_value
    crystal.material_override = crystal_material
    parent.add_child(crystal)
    var light := OmniLight3D.new()
    light.position = crystal_position
    light.light_color = Color(0.12, 0.55, 1.0)
    light.light_energy = 0.8
    light.omni_range = 5.0 * scale_value
    parent.add_child(light)
    if scale_value >= 1.0:
        shrine_crystal_light = light

func _create_torches() -> void:
    for z_position in [-13.0, -27.0, -38.0]:
        for side in [-1.0, 1.0]:
            var torch := Node3D.new()
            torch.position = Vector3(side * 3.8, 0, z_position)
            add_child(torch)
            var pole := MeshInstance3D.new()
            var pole_mesh := CylinderMesh.new()
            pole_mesh.top_radius = 0.07
            pole_mesh.bottom_radius = 0.12
            pole_mesh.height = 1.8
            pole.mesh = pole_mesh
            pole.position.y = 0.9
            pole.material_override = bark_material
            torch.add_child(pole)
            var flame := MeshInstance3D.new()
            var flame_mesh := SphereMesh.new()
            flame_mesh.radius = 0.20
            flame_mesh.height = 0.48
            flame.mesh = flame_mesh
            flame.position.y = 1.92
            flame.material_override = torch_material
            torch.add_child(flame)
            torch_flames.append(flame)
            var embers := CPUParticles3D.new()
            embers.name = "TorchEmbers"
            embers.position = Vector3(0.0, 1.98, 0.0)
            embers.amount = 12
            embers.lifetime = 0.85
            embers.emitting = true
            embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
            embers.emission_sphere_radius = 0.10
            embers.direction = Vector3(0.0, 1.0, 0.0)
            embers.spread = 22.0
            embers.initial_velocity_min = 0.18
            embers.initial_velocity_max = 0.85
            embers.gravity = Vector3(0.0, -0.28, 0.0)
            embers.scale_amount_min = 0.012
            embers.scale_amount_max = 0.035
            embers.color = Color(1.0, 0.34, 0.06, 0.92)
            torch.add_child(embers)
            var smoke := CPUParticles3D.new()
            smoke.name = "TorchSmoke"
            smoke.position = Vector3(0.0, 2.02, 0.0)
            smoke.amount = 8
            smoke.lifetime = 2.8
            smoke.emitting = true
            smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
            smoke.emission_sphere_radius = 0.07
            smoke.direction = Vector3(0.0, 1.0, 0.0)
            smoke.spread = 12.0
            smoke.initial_velocity_min = 0.035
            smoke.initial_velocity_max = 0.12
            smoke.gravity = Vector3(0.0, 0.025, 0.0)
            smoke.scale_amount_min = 0.045
            smoke.scale_amount_max = 0.12
            smoke.color = Color(0.22, 0.24, 0.26, 0.22)
            torch.add_child(smoke)
            var light := OmniLight3D.new()
            light.position.y = 2.0
            light.light_color = Color(1.0, 0.42, 0.16)
            light.light_energy = 0.55
            light.omni_range = 5.0
            torch.add_child(light)
            torch_lights.append(light)

func _create_quest_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "QuestHUD"
    layer.layer = 5
    add_child(layer)
    var panel := ColorRect.new()
    panel.position = Vector2(270, 28)
    panel.size = Vector2(430, 112)
    panel.color = Color(0.025, 0.045, 0.075, 0.82)
    layer.add_child(panel)
    var title := Label.new()
    title.position = Vector2(288, 38)
    title.size = Vector2(400, 30)
    title.text = "MISSÃO: O SEGREDO DO SANTUÁRIO"
    title.add_theme_font_size_override("font_size", 19)
    title.add_theme_color_override("font_color", Color(0.60, 0.83, 1.0))
    layer.add_child(title)
    quest_label = Label.new()
    quest_label.position = Vector2(288, 70)
    quest_label.size = Vector2(390, 28)
    quest_label.add_theme_font_size_override("font_size", 18)
    quest_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    layer.add_child(quest_label)
    quest_detail_label = Label.new()
    quest_detail_label.position = Vector2(288, 98)
    quest_detail_label.size = Vector2(390, 26)
    quest_detail_label.add_theme_font_size_override("font_size", 16)
    quest_detail_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.88))
    layer.add_child(quest_detail_label)

func _refresh_quest_hud() -> void:
    if quest_complete:
        quest_label.text = "Missão concluída!"
        quest_detail_label.text = "Recompensa recebida: +100 EXP"
    elif enemies_defeated < 3:
        quest_label.text = "Derrote os Sombrio  (%d/3)" % enemies_defeated
        quest_detail_label.text = "Encontre os inimigos pela trilha"
    else:
        quest_label.text = "Todos os Sombrio foram derrotados"
        quest_detail_label.text = "Aproxime-se do cristal no santuário"

func _on_enemy_defeated() -> void:
    if quest_complete:
        return
    enemies_defeated = mini(enemies_defeated + 1, 3)
    _refresh_quest_hud()

func _complete_quest() -> void:
    if quest_complete:
        return
    quest_complete = true
    var player := get_node_or_null("Player")
    if player != null and player.has_method("gain_experience"):
        player.call("gain_experience", 100)
    if shrine_crystal_light != null:
        shrine_crystal_light.light_energy = 2.8
        shrine_crystal_light.omni_range = 11.0
        shrine_crystal_light.light_color = Color(0.28, 0.78, 1.0)
    _refresh_quest_hud()


func _create_inventory_hud() -> void:
    var layer := get_node("QuestHUD") as CanvasLayer
    var panel := ColorRect.new()
    panel.position = Vector2(965, 28)
    panel.size = Vector2(285, 170)
    panel.color = Color(0.025, 0.045, 0.075, 0.82)
    layer.add_child(panel)
    var title := Label.new()
    title.position = Vector2(980, 38)
    title.size = Vector2(250, 26)
    title.text = "PERSONAGEM / INVENTÁRIO"
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color(0.60, 0.83, 1.0))
    layer.add_child(title)
    inventory_label = Label.new()
    inventory_label.position = Vector2(980, 68)
    inventory_label.size = Vector2(255, 125)
    inventory_label.add_theme_font_size_override("font_size", 15)
    inventory_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
    layer.add_child(inventory_label)
    pickup_notice_label = Label.new()
    pickup_notice_label.position = Vector2(450, 155)
    pickup_notice_label.size = Vector2(380, 32)
    pickup_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pickup_notice_label.add_theme_font_size_override("font_size", 20)
    pickup_notice_label.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0))
    layer.add_child(pickup_notice_label)
    _refresh_inventory_hud()

func _refresh_inventory_hud() -> void:
    var player := get_node_or_null("Player")
    if player == null or inventory_label == null:
        return
    var lines := PackedStringArray()
    lines.append("Nível %d  |  EXP %d/%d" % [player.get("level"), player.get("experience"), player.get("experience_to_next_level")])
    lines.append("ATQ %d  |  DEF %d  |  VIDA %d/%d" % [player.get("attack_damage"), player.get("defense"), player.get("health"), player.get("max_health")])
    lines.append("Itens:")
    var player_inventory: Dictionary = player.get("inventory")
    if player_inventory.is_empty():
        lines.append("  Inventário vazio")
    else:
        for item_name in player_inventory.keys():
            lines.append("  %s x%d" % [item_name, player_inventory[item_name]])
    lines.append("Amuleto: %s" % ("Equipado" if player.get("equipped_amulet") else "Nenhum"))
    inventory_label.text = "\n".join(lines)

func _create_pickups() -> void:
    _create_pickup("Erva medicinal", Vector3(2.0, 0.65, -8.0), Color(0.25, 0.88, 0.38), false)
    _create_pickup("Cristal azul", Vector3(-2.0, 0.65, -14.0), Color(0.12, 0.62, 1.0), false)
    _create_pickup("Minério antigo", Vector3(4.0, 0.65, -22.0), Color(0.72, 0.55, 0.34), false)
    _create_pickup("Erva medicinal", Vector3(-3.0, 0.65, -29.0), Color(0.25, 0.88, 0.38), false)
    _create_pickup("Amuleto do Guardião", Vector3(0.0, 0.9, -33.0), Color(0.95, 0.72, 0.20), true)

func _create_pickup(item_name: String, pickup_position: Vector3, glow_color: Color, is_equipment: bool) -> void:
    var pickup := Node3D.new()
    pickup.name = "Pickup_" + item_name.replace(" ", "")
    pickup.position = pickup_position
    add_child(pickup)
    var mesh_instance := MeshInstance3D.new()
    if is_equipment:
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.18
        mesh.outer_radius = 0.32
        mesh_instance.mesh = mesh
        mesh_instance.rotation.x = PI * 0.5
    elif item_name == "Cristal azul":
        var mesh := PrismMesh.new()
        mesh.size = Vector3(0.55, 0.85, 0.55)
        mesh_instance.mesh = mesh
    elif item_name == "Minério antigo":
        var mesh := SphereMesh.new()
        mesh.radius = 0.34
        mesh.height = 0.68
        mesh.radial_segments = 6
        mesh.rings = 4
        mesh_instance.mesh = mesh
        mesh_instance.scale = Vector3(1.0, 0.8, 1.25)
    else:
        var mesh := SphereMesh.new()
        mesh.radius = 0.30
        mesh.height = 0.58
        mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = glow_color
    material.metallic = 0.35
    material.roughness = 0.28
    material.emission_enabled = true
    material.emission = glow_color
    material.emission_energy_multiplier = 0.65
    mesh_instance.material_override = material
    pickup.add_child(mesh_instance)
    var light := OmniLight3D.new()
    light.light_color = glow_color
    light.light_energy = 0.45
    light.omni_range = 3.0
    pickup.add_child(light)
    var label := Label3D.new()
    label.text = item_name
    label.position.y = 0.75
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 24
    label.outline_size = 5
    label.modulate = Color(0.92, 0.97, 1.0)
    pickup.add_child(label)
    pickups.append({"node": pickup, "item": item_name, "equipment": is_equipment, "phase": rng.randf_range(0.0, TAU)})

func _update_pickups(delta: float) -> void:
    var player := get_node_or_null("Player") as Node3D
    if player == null:
        return
    for index in range(pickups.size() - 1, -1, -1):
        var pickup_data: Dictionary = pickups[index]
        var pickup := pickup_data["node"] as Node3D
        if not is_instance_valid(pickup):
            pickups.remove_at(index)
            continue
        pickup.rotate_y(delta * 1.25)
        pickup.position.y = 0.65 + sin(Time.get_ticks_msec() * 0.002 + float(pickup_data["phase"])) * 0.12
        if player.global_position.distance_to(pickup.global_position) <= 1.8:
            var item_name: String = pickup_data["item"]
            player.call("add_item", item_name, 1)
            if bool(pickup_data["equipment"]):
                player.call("equip_guardian_amulet")
            pickup_notice_label.text = "Coletado: " + item_name
            pickup.queue_free()
            pickups.remove_at(index)
            _refresh_inventory_hud()
    _refresh_inventory_hud()

func _box(parent: Node3D, part_name: String, part_position: Vector3, dimensions: Vector3, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    parent.add_child(part)

func _spawn_enemies() -> void:
    var spawn_points := [
        Vector3(7.0, 0, -18.0),
        Vector3(-7.0, 0, -26.0),
        Vector3(0.0, 0, -41.0)
    ]
    for i in range(spawn_points.size()):
        var enemy := CharacterBody3D.new()
        enemy.name = "Sombrio_%d" % (i + 1)
        enemy.set_script(ENEMY_SCRIPT)
        enemy.set("player_path", NodePath("../Player"))
        enemy.position = spawn_points[i]
        enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
        add_child(enemy)
