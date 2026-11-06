extends Node3D

const TREE_ASSET := "res://assets/realistic/nature/dead_trees.glb"
const BUSH_ASSET := "res://assets/realistic/nature/bushes.glb"
const GRASS_ASSET := "res://assets/realistic/nature/grass.glb"
const ROCK_ASSET := "res://assets/realistic/nature/rock_large.glb"
const FLOWER_ASSET := "res://assets/realistic/nature/flowers.glb"
const ROCKY_OUTCROP_ASSET := "res://assets/realistic/nature/rocky_outcrop.glb"
const DRY_STONE_WALL_ASSET := "res://assets/realistic/nature/dry_stone_wall_section.glb"

var rng := RandomNumberGenerator.new()
var loaded_assets: Dictionary = {}

func _ready() -> void:
    rng.seed = 771204
    _load_nature_assets()
    _place_tree_line()
    _place_photorealistic_rock_formations()
    _scatter_real_vegetation()
    _scatter_real_rocks()
    _decorate_shrine_approach()
    call_deferred("_apply_post_fx")

func _load_nature_assets() -> void:
    for path in [TREE_ASSET, BUSH_ASSET, GRASS_ASSET, ROCK_ASSET, FLOWER_ASSET, ROCKY_OUTCROP_ASSET, DRY_STONE_WALL_ASSET]:
        var resource := load(path)
        if resource is PackedScene:
            loaded_assets[path] = resource
        else:
            push_warning("Aetheria: asset 3D não pôde ser carregado: " + path)

func _instance_asset(path: String, position: Vector3, uniform_scale: float, yaw: float = 0.0) -> void:
    var packed: PackedScene = loaded_assets.get(path)
    if packed == null:
        return
    var instance := packed.instantiate() as Node3D
    if instance == null:
        push_warning("Aetheria: a raiz do asset não é Node3D: " + path)
        return
    instance.position = position
    instance.rotation.y = yaw
    instance.scale = Vector3.ONE * uniform_scale
    add_child(instance)

func _valid_scatter_position(pos: Vector3) -> bool:
    # Keep the spawn lane and the approach to the shrine clear.
    if absf(pos.x) < 4.8 and pos.z < 8.0 and pos.z > -39.0:
        return false
    if pos.distance_to(Vector3(0, 0, -35)) < 7.0:
        return false
    return true

func _place_tree_line() -> void:
    # Tree assets are placed outside the playable corridor to frame the valley.
    var positions := [
        Vector3(-17.0, 0.0, -8.0), Vector3(-23.0, 0.0, -22.0),
        Vector3(-18.0, 0.0, -43.0), Vector3(-30.0, 0.0, 5.0),
        Vector3(18.0, 0.0, -10.0), Vector3(24.0, 0.0, -27.0),
        Vector3(19.0, 0.0, -46.0), Vector3(31.0, 0.0, 3.0)
    ]
    for i in range(positions.size()):
        _instance_asset(TREE_ASSET, positions[i], rng.randf_range(0.85, 1.2), rng.randf_range(0.0, TAU))

func _place_photorealistic_rock_formations() -> void:
    _instance_asset(ROCKY_OUTCROP_ASSET, Vector3(-22.0, 0.0, -34.0), 0.78, 0.35)
    _instance_asset(ROCKY_OUTCROP_ASSET, Vector3(22.0, 0.0, -38.0), 0.72, -0.55)
    for side in [-1.0, 1.0]:
        for z in [-12.0, -18.0, -24.0, -30.0]:
            _instance_asset(DRY_STONE_WALL_ASSET, Vector3(side * 6.2, 0.0, z), 1.0, PI * 0.5)

func _scatter_real_vegetation() -> void:
    for i in range(18):
        var pos := Vector3(rng.randf_range(-38.0, 38.0), 0.0, rng.randf_range(-47.0, 43.0))
        if _valid_scatter_position(pos):
            _instance_asset(BUSH_ASSET, pos, rng.randf_range(0.7, 1.15), rng.randf_range(0.0, TAU))
    for i in range(30):
        var pos := Vector3(rng.randf_range(-39.0, 39.0), 0.0, rng.randf_range(-48.0, 45.0))
        if _valid_scatter_position(pos):
            _instance_asset(GRASS_ASSET, pos, rng.randf_range(0.65, 1.25), rng.randf_range(0.0, TAU))
    for i in range(12):
        var pos := Vector3(rng.randf_range(-37.0, 37.0), 0.0, rng.randf_range(-44.0, 42.0))
        if _valid_scatter_position(pos):
            _instance_asset(FLOWER_ASSET, pos, rng.randf_range(0.65, 1.05), rng.randf_range(0.0, TAU))

func _scatter_real_rocks() -> void:
    for i in range(22):
        var pos := Vector3(rng.randf_range(-43.0, 43.0), 0.0, rng.randf_range(-49.0, 47.0))
        if _valid_scatter_position(pos):
            _instance_asset(ROCK_ASSET, pos, rng.randf_range(0.65, 1.8), rng.randf_range(0.0, TAU))

func _decorate_shrine_approach() -> void:
    # Keep the shrine approach readable; real rock assets mark its edges.
    for side in [-1.0, 1.0]:
        for z in [-29.0, -33.0, -37.0]:
            _instance_asset(ROCK_ASSET, Vector3(side * 5.6, 0.0, z), rng.randf_range(0.45, 0.7), rng.randf_range(0.0, TAU))

func _apply_post_fx() -> void:
    var world := get_parent()
    if world == null:
        return
    var environment_node := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if environment_node != null and environment_node.environment != null:
        environment_node.environment.glow_enabled = true
        environment_node.environment.glow_intensity = 0.32
        environment_node.environment.glow_strength = 0.78
        environment_node.environment.fog_enabled = true
        environment_node.environment.fog_light_color = Color(0.39, 0.52, 0.55)
        environment_node.environment.fog_density = 0.008
    var sun := world.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
    if sun != null:
        sun.light_color = Color(1.0, 0.86, 0.70)
        sun.light_energy = 1.3
        sun.directional_shadow_max_distance = 58.0
