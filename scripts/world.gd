extends Node3D

const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

var rng := RandomNumberGenerator.new()
var bark_material: StandardMaterial3D
var leaf_materials: Array[StandardMaterial3D] = []
var stone_material: StandardMaterial3D
var dark_stone_material: StandardMaterial3D
var path_material: StandardMaterial3D
var crystal_material: StandardMaterial3D
var torch_material: StandardMaterial3D

func _ready() -> void:
    rng.seed = 48291
    _create_materials()
    _create_environment()
    _create_ground()
    _create_path()
    _create_forest()
    _create_rock_fields()
    _create_ancient_shrine()
    _create_torches()
    _spawn_enemies()

func _create_materials() -> void:
    bark_material = _material(Color(0.25, 0.14, 0.085), 1.0)
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
        _material(Color(0.10, 0.29, 0.15), 1.0),
        _material(Color(0.13, 0.36, 0.18), 1.0),
        _material(Color(0.18, 0.40, 0.20), 1.0),
        _material(Color(0.22, 0.34, 0.15), 1.0)
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
    sky_material.sky_top_color = Color(0.12, 0.23, 0.42)
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
    world_env.fog_density = 0.006
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
    var grass := _material(Color(0.20, 0.36, 0.20), 1.0)
    mesh_instance.material_override = grass
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

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.20
    trunk_mesh.bottom_radius = 0.34
    trunk_mesh.height = 2.6
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.3
    trunk.material_override = bark_material
    tree.add_child(trunk)

    for j in range(3):
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.15 - float(j) * 0.10
        crown_mesh.height = 2.15 - float(j) * 0.12
        crown.mesh = crown_mesh
        crown.position = Vector3(0, 2.55 + float(j) * 0.62, 0)
        crown.material_override = leaf_materials[rng.randi_range(0, leaf_materials.size() - 1)]
        tree.add_child(crown)

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

    _box(shrine, "Shrine platform", Vector3(0, 0.18, 0), Vector3(10, 0.36, 7), dark_stone_material)
    _box(shrine, "Upper step", Vector3(0, 0.43, 0.1), Vector3(7.5, 0.22, 5.2), stone_material)

    for side in [-1.0, 1.0]:
        for depth in [-1.0, 1.0]:
            _box(shrine, "Ancient pillar", Vector3(side * 3.1, 2.05, depth * 1.75), Vector3(0.72, 3.25, 0.72), stone_material)
            _box(shrine, "Pillar base", Vector3(side * 3.1, 0.62, depth * 1.75), Vector3(1.05, 0.34, 1.05), dark_stone_material)

    _box(shrine, "Broken lintel", Vector3(0, 3.82, -1.75), Vector3(7.0, 0.55, 0.85), dark_stone_material)
    _box(shrine, "Altar", Vector3(0, 1.05, -0.45), Vector3(2.2, 1.1, 1.55), dark_stone_material)
    _box(shrine, "Altar top", Vector3(0, 1.66, -0.45), Vector3(2.65, 0.18, 1.9), stone_material)
    _create_crystal(shrine, Vector3(0, 2.45, -0.45), 1.0)
    _create_crystal(shrine, Vector3(-4.4, 1.1, 0), 0.55)
    _create_crystal(shrine, Vector3(4.4, 1.1, 0), 0.55)

    var title := Label3D.new()
    title.text = "SANTUARIO ANTIGO"
    title.position = Vector3(0, 4.8, -1.8)
    title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    title.font_size = 40
    title.outline_size = 8
    title.modulate = Color(0.78, 0.91, 1.0)
    shrine.add_child(title)

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
            var light := OmniLight3D.new()
            light.position.y = 2.0
            light.light_color = Color(1.0, 0.42, 0.16)
            light.light_energy = 0.55
            light.omni_range = 5.0
            torch.add_child(light)

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
        add_child(enemy)
