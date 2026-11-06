extends Node3D

const HERO_MODEL_PATH := "res://assets/realistic/characters/man-base-character-rigged.glb"
const SWORD_MODEL_PATH := "res://assets/realistic/weapons/fantasy-sword-light.glb"

var hero_root: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var sword_root: Node3D
var cape_mesh: MeshInstance3D
var current_animation := ""
var attack_time := 0.0
var sword_rest_rotation := Vector3.ZERO
var walk_phase := 0.0

func _ready() -> void:
    _load_hero()
    if hero_root != null:
        _create_cape()
        _create_armor_details()
        _attach_sword()

func _process(delta: float) -> void:
    attack_time = maxf(0.0, attack_time - delta)
    if sword_root != null:
        if attack_time > 0.0:
            var progress := 1.0 - attack_time / 0.42
            var slash := sin(clampf(progress, 0.0, 1.0) * PI)
            sword_root.rotation = sword_rest_rotation + Vector3(-slash * 1.25, 0.0, slash * 0.45)
        else:
            sword_root.rotation = sword_root.rotation.lerp(sword_rest_rotation, minf(1.0, delta * 14.0))
    if cape_mesh != null:
        var speed_factor := 1.0 if current_animation.to_lower().contains("walk") or current_animation.to_lower().contains("run") else 0.0
        cape_mesh.rotation.x = lerpf(cape_mesh.rotation.x, -0.025 - speed_factor * 0.055, minf(1.0, delta * 5.0))
        cape_mesh.rotation.z = lerpf(cape_mesh.rotation.z, sin(walk_phase) * 0.025 * speed_factor, minf(1.0, delta * 5.0))

func _load_hero() -> void:
    var packed := load(HERO_MODEL_PATH) as PackedScene
    if packed == null:
        push_error("Aetheria: modelo real do protagonista ausente: " + HERO_MODEL_PATH)
        return
    hero_root = packed.instantiate() as Node3D
    if hero_root == null:
        push_error("Aetheria: o modelo do protagonista não possui raiz Node3D.")
        return
    hero_root.name = "HeroHighDetail"
    hero_root.position.y = -0.9
    hero_root.rotation.y = PI
    add_child(hero_root)

    skeleton = _find_skeleton(hero_root)
    animation_player = _find_animation_player(hero_root)
    if skeleton == null:
        push_error("Aetheria: o modelo do protagonista foi importado sem Skeleton3D.")
    if animation_player == null:
        push_error("Aetheria: o modelo do protagonista foi importado sem AnimationPlayer.")
    else:
        for animation_name in animation_player.get_animation_list():
            print("Aetheria hero animation: ", animation_name)

    _tint_hero_materials(hero_root)

func _find_skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D:
        return node as Skeleton3D
    for child in node.get_children():
        var found := _find_skeleton(child)
        if found != null:
            return found
    return null

func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child in node.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null

func _tint_hero_materials(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        var mesh := mesh_instance.mesh
        if mesh != null:
            for surface in range(mesh.get_surface_count()):
                var source := mesh_instance.get_active_material(surface)
                if source is BaseMaterial3D:
                    var material := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
                    var key := (material.resource_name + " " + mesh_instance.name).to_lower()
                    if "hair" in key:
                        material.albedo_color = Color(0.018, 0.022, 0.035)
                        material.roughness = 0.62
                    elif "eye" in key:
                        material.albedo_color = Color(0.08, 0.42, 0.95)
                        material.emission_enabled = true
                        material.emission = Color(0.015, 0.08, 0.32)
                    elif "shirt" in key or "top" in key or "cloth" in key:
                        material.albedo_color = Color(0.035, 0.075, 0.17)
                        material.roughness = 0.78
                    elif "short" in key or "pant" in key or "trouser" in key:
                        material.albedo_color = Color(0.025, 0.032, 0.055)
                        material.roughness = 0.9
                    mesh_instance.set_surface_override_material(surface, material)
    for child in node.get_children():
        _tint_hero_materials(child)

func _find_bone_index(terms: Array[String]) -> int:
    if skeleton == null:
        return -1
    for i in range(skeleton.get_bone_count()):
        var bone_name := skeleton.get_bone_name(i).to_lower().replace("_", "").replace(" ", "")
        var matches := true
        for term in terms:
            if not bone_name.contains(term):
                matches = false
                break
        if matches:
            return i
    return -1

func _bone_attachment(bone_index: int, node_name: String) -> BoneAttachment3D:
    if skeleton == null or bone_index < 0:
        return null
    var attachment := BoneAttachment3D.new()
    attachment.name = node_name
    attachment.bone_idx = bone_index
    skeleton.add_child(attachment)
    return attachment

func _create_cape() -> void:
    # A shaped cloth surface with folds, not a flat card or a primitive box.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rows := 18
    var columns := 14
    for row in range(rows):
        var v := float(row) / float(rows - 1)
        var width := lerpf(0.31, 0.62, v)
        for column in range(columns):
            var u := float(column) / float(columns - 1)
            var x := lerpf(-width, width, u)
            var y := 1.48 - v * 1.04
            var z := 0.24 + 0.075 * v + sin(u * PI * 5.0 + v * 2.1) * 0.028 * v
            z += sin(v * PI * 2.0) * 0.018
            surface.set_uv(Vector2(u, v))
            surface.add_vertex(Vector3(x, y, z))
    for row in range(rows - 1):
        for column in range(columns - 1):
            var a := row * columns + column
            var b := a + 1
            var c := a + columns
            var d := c + 1
            surface.add_index(a)
            surface.add_index(c)
            surface.add_index(b)
            surface.add_index(b)
            surface.add_index(c)
            surface.add_index(d)
    surface.generate_normals()
    var mesh := surface.commit()
    cape_mesh = MeshInstance3D.new()
    cape_mesh.name = "HeroBlueClothCape"
    cape_mesh.mesh = mesh
    var cloth := StandardMaterial3D.new()
    cloth.albedo_color = Color(0.025, 0.105, 0.31)
    cloth.roughness = 0.88
    cloth.metallic = 0.02
    cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
    cloth.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    cape_mesh.material_override = cloth
    hero_root.add_child(cape_mesh)

    # White crest on the back: a raised, beveled cross built as a small mesh.
    var crest := MeshInstance3D.new()
    crest.name = "CapeWhiteCrest"
    crest.mesh = _make_crest_mesh()
    var white := StandardMaterial3D.new()
    white.albedo_color = Color(0.88, 0.94, 1.0)
    white.metallic = 0.18
    white.roughness = 0.32
    crest.material_override = white
    crest.position = Vector3(0.0, 1.13, 0.315)
    hero_root.add_child(crest)

func _make_crest_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _add_quad(st, Vector3(-0.035, 0.18, 0), Vector3(0.035, 0.18, 0), Vector3(-0.035, -0.20, 0), Vector3(0.035, -0.20, 0))
    _add_quad(st, Vector3(-0.15, 0.06, 0), Vector3(0.15, 0.06, 0), Vector3(-0.15, -0.01, 0), Vector3(0.15, -0.01, 0))
    st.generate_normals()
    return st.commit()

func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(b)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(d)

func _create_armor_details() -> void:
    # Curved chest plate with raised central ridge and metallic PBR finish.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rows := 12
    var columns := 14
    for row in range(rows):
        var v := float(row) / float(rows - 1)
        for column in range(columns):
            var u := float(column) / float(columns - 1)
            var x := lerpf(-0.205, 0.205, u)
            var y := lerpf(1.37, 0.99, v)
            var z := -0.205 - (1.0 - absf(x) / 0.205) * 0.035 - sin(v * PI) * 0.025
            st.set_uv(Vector2(u, v))
            st.add_vertex(Vector3(x, y, z))
    for row in range(rows - 1):
        for column in range(columns - 1):
            var a := row * columns + column
            var b := a + 1
            var c := a + columns
            var d := c + 1
            st.add_index(a)
            st.add_index(b)
            st.add_index(c)
            st.add_index(b)
            st.add_index(d)
            st.add_index(c)
    st.generate_normals()
    var plate := MeshInstance3D.new()
    plate.name = "MidnightSteelChestPlate"
    plate.mesh = st.commit()
    var steel := StandardMaterial3D.new()
    steel.albedo_color = Color(0.045, 0.085, 0.15)
    steel.metallic = 0.82
    steel.roughness = 0.26
    plate.material_override = steel
    hero_root.add_child(plate)

    # Layered shoulder shells are curved surfaces with real thickness.
    for side in [-1.0, 1.0]:
        var pauldron := MeshInstance3D.new()
        pauldron.name = "BlueSteelPauldron"
        pauldron.mesh = _make_pauldron_mesh()
        pauldron.position = Vector3(side * 0.34, 1.43, -0.015)
        pauldron.scale = Vector3(0.22, 0.15, 0.22)
        pauldron.material_override = steel
        hero_root.add_child(pauldron)

func _make_pauldron_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings := 8
    var segments := 20
    for ring in range(rings):
        var v := float(ring) / float(rings - 1)
        var theta := v * PI * 0.5
        for segment in range(segments):
            var angle := float(segment) / float(segments) * TAU
            var x := sin(theta) * cos(angle)
            var y := cos(theta)
            var z := sin(theta) * sin(angle)
            st.add_vertex(Vector3(x, y, z))
    for ring in range(rings - 1):
        for segment in range(segments):
            var a := ring * segments + segment
            var b := ring * segments + (segment + 1) % segments
            var c := a + segments
            var d := (ring * segments + (segment + 1) % segments) + segments
            st.add_index(a)
            st.add_index(c)
            st.add_index(b)
            st.add_index(b)
            st.add_index(c)
            st.add_index(d)
    st.generate_normals()
    return st.commit()

func _attach_sword() -> void:
    var packed := load(SWORD_MODEL_PATH) as PackedScene
    if packed == null:
        push_error("Aetheria: espada real ausente: " + SWORD_MODEL_PATH)
        return
    var sword := packed.instantiate() as Node3D
    if sword == null:
        push_error("Aetheria: modelo da espada não é Node3D.")
        return

    var hand_index := _find_bone_index(["righthand"])
    if hand_index < 0:
        hand_index = _find_bone_index(["hand", "r"])
    if hand_index < 0:
        hand_index = _find_bone_index(["right", "hand"])
    var attachment := _bone_attachment(hand_index, "RightHandWeaponAttachment")
    if attachment == null:
        attachment = Node3D.new()
        attachment.name = "RightHandWeaponFallback"
        attachment.position = Vector3(0.38, 0.86, -0.12)
        hero_root.add_child(attachment)

    sword_root = Node3D.new()
    sword_root.name = "HeroLegendarySword"
    sword_root.scale = Vector3.ONE * 0.78
    # The source GLB is laid flat; rotate its long axis upright in the grip.
    sword_root.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
    sword_root.position = Vector3(0.0, 0.0, 0.0)
    attachment.add_child(sword_root)
    sword_root.add_child(sword)
    sword.position = Vector3.ZERO
    sword_rest_rotation = sword_root.rotation

func animate_character(delta: float, horizontal_speed: float, airborne: bool) -> void:
    walk_phase += delta * (5.0 + horizontal_speed * 1.7)
    if animation_player == null:
        return
    var target := ""
    if airborne:
        target = _animation_with("jump")
        if target == "":
            target = _animation_with("run")
    elif horizontal_speed > 0.25:
        target = _animation_with("run") if horizontal_speed > 6.0 else _animation_with("walk")
        if target == "":
            target = _animation_with("run")
    else:
        target = _animation_with("idle")
    if target == "":
        if animation_player.is_playing():
            animation_player.stop()
        current_animation = ""
        return
    if current_animation != target:
        current_animation = target
        animation_player.play(target, 0.18)
    animation_player.speed_scale = clampf(horizontal_speed / 5.8, 0.75, 1.35) if horizontal_speed > 0.25 else 1.0

func _animation_with(fragment: String) -> String:
    if animation_player == null:
        return ""
    for animation_name in animation_player.get_animation_list():
        if String(animation_name).to_lower().contains(fragment):
            return String(animation_name)
    return ""

func play_attack() -> void:
    attack_time = 0.42
    var attack_animation := _animation_with("attack")
    if animation_player != null and attack_animation != "":
        animation_player.play(attack_animation, 0.06)
        current_animation = attack_animation
