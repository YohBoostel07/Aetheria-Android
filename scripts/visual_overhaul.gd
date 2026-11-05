extends Node3D

var rng := RandomNumberGenerator.new()
var moss: StandardMaterial3D
var fern_green: StandardMaterial3D
var flower_blue: StandardMaterial3D
var rock_dark: StandardMaterial3D
var mountain_mat: StandardMaterial3D

func _ready() -> void:
    rng.seed = 771204
    _make_materials()
    _create_distant_ridges()
    _scatter_undergrowth()
    _scatter_mossy_stones()
    _decorate_shrine_approach()
    call_deferred("_apply_post_fx")

func _make_materials() -> void:
    moss = _mat(Color(0.075, 0.19, 0.075), 0.98)
    fern_green = _mat(Color(0.12, 0.31, 0.12), 0.92)
    flower_blue = _mat(Color(0.20, 0.48, 0.72), 0.55)
    rock_dark = _mat(Color(0.17, 0.20, 0.21), 0.96)
    mountain_mat = _mat(Color(0.16, 0.22, 0.23), 1.0)

func _mat(color: Color, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    return m

func _create_distant_ridges() -> void:
    for i in range(17):
        var peak := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(7.0, 13.0)
        mesh.height = rng.randf_range(17.0, 28.0)
        mesh.radial_segments = 12
        mesh.rings = 7
        peak.mesh = mesh
        var side := -1.0 if i % 2 == 0 else 1.0
        var z := -55.0 + float(i) * 7.0
        peak.position = Vector3(side * rng.randf_range(58.0, 78.0), mesh.height * 0.28 - 1.0, z)
        peak.scale = Vector3(rng.randf_range(0.8, 1.35), 1.0, rng.randf_range(0.8, 1.5))
        peak.material_override = mountain_mat
        add_child(peak)

func _scatter_undergrowth() -> void:
    for i in range(54):
        var plant := Node3D.new()
        plant.position = Vector3(rng.randf_range(-42.0, 42.0), 0.0, rng.randf_range(-45.0, 45.0))
        if absf(plant.position.x) < 4.0 and plant.position.z < 8.0 and plant.position.z > -39.0:
            continue
        if plant.position.distance_to(Vector3(0, 0, -35)) < 8.0:
            continue
        add_child(plant)
        var fronds := rng.randi_range(5, 8)
        for j in range(fronds):
            var angle := TAU * float(j) / float(fronds) + rng.randf_range(-0.2, 0.2)
            var leaf := MeshInstance3D.new()
            var leaf_mesh := SphereMesh.new()
            leaf_mesh.radius = rng.randf_range(0.10, 0.17)
            leaf_mesh.height = rng.randf_range(0.65, 0.95)
            leaf_mesh.radial_segments = 7
            leaf_mesh.rings = 5
            leaf.mesh = leaf_mesh
            leaf.position = Vector3(cos(angle) * 0.22, rng.randf_range(0.18, 0.34), sin(angle) * 0.22)
            leaf.rotation = Vector3(-0.65, angle, 0.78)
            leaf.scale = Vector3(0.55, 1.0, 0.42)
            leaf.material_override = fern_green
            plant.add_child(leaf)
        if i % 4 == 0:
            _add_flower(plant)

func _add_flower(parent: Node3D) -> void:
    var stem := MeshInstance3D.new()
    var stem_mesh := CylinderMesh.new()
    stem_mesh.top_radius = 0.008
    stem_mesh.bottom_radius = 0.018
    stem_mesh.height = 0.34
    stem.mesh = stem_mesh
    stem.position.y = 0.17
    stem.material_override = fern_green
    parent.add_child(stem)
    for petal in range(5):
        var bloom := MeshInstance3D.new()
        var petal_mesh := SphereMesh.new()
        petal_mesh.radius = 0.075
        petal_mesh.height = 0.12
        bloom.mesh = petal_mesh
        var angle := TAU * float(petal) / 5.0
        bloom.position = Vector3(cos(angle) * 0.09, 0.37, sin(angle) * 0.09)
        bloom.material_override = flower_blue
        parent.add_child(bloom)

func _scatter_mossy_stones() -> void:
    for i in range(32):
        var stone := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.25, 0.78)
        mesh.height = mesh.radius * rng.randf_range(0.9, 1.5)
        mesh.radial_segments = 8
        mesh.rings = 5
        stone.mesh = mesh
        stone.scale = Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.5, 0.9), rng.randf_range(0.8, 1.4))
        stone.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.0, TAU), rng.randf_range(-0.2, 0.2))
        stone.position = Vector3(rng.randf_range(-48.0, 48.0), 0.18, rng.randf_range(-48.0, 48.0))
        if absf(stone.position.x) < 4.0 and stone.position.z < 8.0 and stone.position.z > -39.0:
            continue
        stone.material_override = rock_dark
        add_child(stone)
        if i % 3 == 0:
            var moss_cap := MeshInstance3D.new()
            var cap_mesh := SphereMesh.new()
            cap_mesh.radius = mesh.radius * 0.55
            cap_mesh.height = mesh.radius * 0.38
            cap_mesh.radial_segments = 8
            cap_mesh.rings = 4
            moss_cap.mesh = cap_mesh
            moss_cap.position = stone.position + Vector3(0, mesh.radius * 0.42, 0)
            moss_cap.material_override = moss
            add_child(moss_cap)

func _decorate_shrine_approach() -> void:
    for side in [-1.0, 1.0]:
        for z in [-31.0, -34.0, -37.0]:
            var rune_stone := MeshInstance3D.new()
            var rune_mesh := CylinderMesh.new()
            rune_mesh.top_radius = 0.34
            rune_mesh.bottom_radius = 0.42
            rune_mesh.height = 0.28
            rune_mesh.radial_segments = 8
            rune_stone.mesh = rune_mesh
            rune_stone.position = Vector3(side * 5.4, 0.14, z)
            rune_stone.material_override = rock_dark
            add_child(rune_stone)
