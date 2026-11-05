extends Node3D

const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

func _ready() -> void:
    _create_environment()
    _create_ground()
    _create_landmarks()
    _spawn_enemies()

func _create_environment() -> void:
    var world_env := Environment.new()
    world_env.background_mode = Environment.BG_SKY
    world_env.sky = Sky.new()
    world_env.sky.sky_material = ProceduralSkyMaterial.new()
    world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world_env.ambient_light_color = Color(0.63, 0.72, 0.84)
    world_env.ambient_light_energy = 0.65
    world_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
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
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.24, 0.43, 0.24)
    mat.roughness = 1.0
    mesh_instance.material_override = mat
    ground.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(180, 0.3, 180)
    collision.shape = shape
    collision.position.y = -0.15
    ground.add_child(collision)

func _create_landmarks() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 48291
    for i in range(42):
        var tree := Node3D.new()
        tree.position = Vector3(rng.randf_range(-48, 48), 0, rng.randf_range(-48, 48))
        if tree.position.distance_to(Vector3(0, 0, 4)) < 8:
            continue
        add_child(tree)
        var trunk := MeshInstance3D.new()
        var trunk_mesh := CylinderMesh.new()
        trunk_mesh.top_radius = 0.22
        trunk_mesh.bottom_radius = 0.34
        trunk_mesh.height = 2.2
        trunk.mesh = trunk_mesh
        trunk.position.y = 1.1
        var bark := StandardMaterial3D.new()
        bark.albedo_color = Color(0.29, 0.17, 0.1)
        trunk.material_override = bark
        tree.add_child(trunk)
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.35
        crown_mesh.height = 2.5
        crown.mesh = crown_mesh
        crown.position.y = 2.65
        var leaves := StandardMaterial3D.new()
        leaves.albedo_color = Color(0.12 + rng.randf() * 0.08, 0.34 + rng.randf() * 0.16, 0.17)
        leaves.roughness = 1.0
        crown.material_override = leaves
        tree.add_child(crown)

func _spawn_enemies() -> void:
    var player := get_node("Player") as CharacterBody3D
    var spawn_points := [
        Vector3(5.5, 0, -2.0),
        Vector3(-6.0, 0, -5.0),
        Vector3(9.0, 0, -10.0)
    ]
    for i in range(spawn_points.size()):
        var enemy := CharacterBody3D.new()
        enemy.name = "Sombrio_%d" % (i + 1)
        enemy.set_script(ENEMY_SCRIPT)
        enemy.set("player_path", NodePath("../Player"))
        enemy.position = spawn_points[i]
        add_child(enemy)
