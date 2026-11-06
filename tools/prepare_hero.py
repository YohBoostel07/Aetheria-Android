import bpy
import math
import sys
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
source_path, output_path = args[0], args[1]

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source_path)

armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
if not armatures:
    raise RuntimeError("Rigged protagonist GLB has no armature")
armature = armatures[0]
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if not meshes:
    raise RuntimeError("Rigged protagonist GLB has no mesh")

def norm(value):
    return value.lower().replace("_", "").replace(".", "").replace(":", "").replace(" ", "")

def find_bone(*terms):
    for bone in armature.data.bones:
        name = norm(bone.name)
        if all(term in name for term in terms):
            return bone.name
    return None

def find_alias(aliases, excluded=()):
    for bone in armature.data.bones:
        name = norm(bone.name)
        if any(all(term in name for term in alias) for alias in aliases) and not any(term in name for term in excluded):
            return bone.name
    return None

bones = {
    "hips": find_bone("hips"),
    "spine": find_bone("spine02") or find_bone("spine"),
    "chest": find_bone("spine03") or find_bone("chest") or find_bone("spine01"),
    "head": find_bone("head"),
    "upper_arm_r": find_alias([("rightarm",), ("upperarmr",), ("armr",)], ("forearm", "lower")),
    "lower_arm_r": find_alias([("rightforearm",), ("lowerarmr",), ("forearmr",)]),
    "upper_arm_l": find_alias([("leftarm",), ("upperarml",), ("arml",)], ("forearm", "lower")),
    "lower_arm_l": find_alias([("leftforearm",), ("lowerarml",), ("forearml",)]),
    "upper_leg_r": find_alias([("rightupleg",), ("upperlegr",), ("uplegr",), ("thighr",)]),
    "lower_leg_r": find_alias([("rightleg",), ("lowerlegr",), ("calfr",)], ("upper", "thigh")),
    "upper_leg_l": find_alias([("leftupleg",), ("upperlegl",), ("uplegl",), ("thighl",)]),
    "lower_leg_l": find_alias([("leftleg",), ("lowerlegl",), ("calfl",)], ("upper", "thigh")),
}
print("HERO_RIG_BONES", bones)
print("HERO_ALL_BONE_NAMES", [bone.name for bone in armature.data.bones])
for mesh_object in meshes:
    slot_report = []
    for slot in mesh_object.material_slots:
        material = slot.material
        image_names = []
        if material and material.use_nodes and material.node_tree:
            for node in material.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    image_names.append(node.image.name)
        slot_report.append((material.name if material else "None", image_names))
    print("HERO_MESH_MATERIALS", mesh_object.name, slot_report)
    if mesh_object.data.vertices:
        xs = [vertex.co.x for vertex in mesh_object.data.vertices]
        ys = [vertex.co.y for vertex in mesh_object.data.vertices]
        zs = [vertex.co.z for vertex in mesh_object.data.vertices]
        print("HERO_MESH_BOUNDS", mesh_object.name, (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))

# Build fitted dark fabric leg armor on the actual rig, covering the base mesh shorts.
cloth = bpy.data.materials.new("Hero Midnight Cloth PBR")
cloth.diffuse_color = (0.018, 0.028, 0.06, 1.0)
cloth.use_nodes = True
principled = cloth.node_tree.nodes.get("Principled BSDF")
if principled:
    principled.inputs["Base Color"].default_value = (0.018, 0.028, 0.06, 1.0)
    principled.inputs["Roughness"].default_value = 0.88
    principled.inputs["Metallic"].default_value = 0.04

def add_leg_shell(bone_name, object_name, radius_start, radius_end):
    if not bone_name:
        return
    bone = armature.data.bones.get(bone_name)
    if bone is None:
        return
    start = bone.head_local.copy()
    end = bone.tail_local.copy()
    axis_vector = end - start
    length = axis_vector.length
    if length < 0.08:
        return
    axis = axis_vector.normalized()
    tangent = axis.cross(Vector((1.0, 0.0, 0.0))).normalized()
    if tangent.length < 0.01:
        tangent = axis.cross(Vector((0.0, 1.0, 0.0))).normalized()
    bitangent = axis.cross(tangent).normalized()
    vertices = []
    faces = []
    rings = 12
    segments = 16
    for ring in range(rings):
        t = ring / float(rings - 1)
        radius = (radius_start * (1.0 - t) + radius_end * t) * (1.0 + math.sin(t * math.pi * 6.0) * 0.018)
        center = start.lerp(end, t)
        for segment in range(segments):
            angle = math.tau * segment / float(segments)
            offset = tangent * math.cos(angle) * radius + bitangent * math.sin(angle) * radius
            vertices.append(center + offset)
    for ring in range(rings - 1):
        for segment in range(segments):
            a = ring * segments + segment
            b = ring * segments + (segment + 1) % segments
            d = (ring + 1) * segments + (segment + 1) % segments
            e = (ring + 1) * segments + segment
            faces.append((a, b, d, e))
    mesh = bpy.data.meshes.new(object_name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(cloth)
    mesh.update()
    obj = bpy.data.objects.new(object_name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = armature
    obj.matrix_world = armature.matrix_world.copy()
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Hero leg rig", "ARMATURE")
    modifier.object = armature
    meshes.append(obj)

for side in ["r", "l"]:
    upper = bones.get("upper_leg_" + side)
    lower = bones.get("lower_leg_" + side)
    add_leg_shell(upper, "HeroDarkTrousers_" + side.upper(), 0.095, 0.078)
    add_leg_shell(lower, "HeroDarkShin_" + side.upper(), 0.078, 0.066)

for pose_bone in armature.pose.bones:
    pose_bone.rotation_mode = "XYZ"

armature.animation_data_create()
existing_actions = list(bpy.data.actions)
print("HERO_IMPORTED_ACTIONS", [action.name for action in existing_actions])

def set_pose(values):
    for key, rotation in values.items():
        bone_name = bones.get(key)
        if bone_name and armature.pose.bones.get(bone_name):
            armature.pose.bones[bone_name].rotation_euler = rotation
    for pose_bone in armature.pose.bones:
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=bpy.context.scene.frame_current, group=pose_bone.name)
    hips_name = bones.get("hips")
    if hips_name:
        armature.pose.bones[hips_name].keyframe_insert(data_path="location", frame=bpy.context.scene.frame_current, group=hips_name)

def create_action(name, keyed_poses, loop=False):
    action = bpy.data.actions.new(name)
    armature.animation_data.action = action
    for frame, values in keyed_poses:
        bpy.context.scene.frame_set(frame)
        for pose_bone in armature.pose.bones:
            pose_bone.rotation_euler = (0.0, 0.0, 0.0)
            pose_bone.location = (0.0, 0.0, 0.0)
        set_pose(values)
    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = "BEZIER"
        if loop:
            curve.modifiers.new("CYCLES")
    action.use_fake_user = True
    return action

idle_poses = []
for frame, phase in [(1, 0.0), (13, math.pi * 0.5), (25, math.pi), (37, math.pi * 1.5), (49, math.tau)]:
    breath = math.sin(phase) * 0.018
    idle_poses.append((frame, {
        "spine": (breath, 0.0, 0.0),
        "chest": (breath * 0.7, 0.0, 0.0),
        "head": (-breath * 0.35, 0.0, math.sin(phase * 0.5) * 0.012),
        "hips": (0.0, 0.0, math.sin(phase) * 0.006),
    }))
idle = create_action("Idle", idle_poses, True)

jump = create_action("Jump", [
    (1, {}),
    (4, {"hips": (0.0, 0.0, -0.035), "upper_leg_r": (0.38, 0.0, 0.0), "upper_leg_l": (0.38, 0.0, 0.0), "lower_leg_r": (-0.62, 0.0, 0.0), "lower_leg_l": (-0.62, 0.0, 0.0), "upper_arm_r": (-0.32, 0.0, 0.0), "upper_arm_l": (-0.32, 0.0, 0.0)}),
    (9, {"hips": (0.0, 0.0, 0.055), "spine": (-0.10, 0.0, 0.0), "upper_leg_r": (-0.18, 0.0, 0.0), "upper_leg_l": (-0.18, 0.0, 0.0), "lower_leg_r": (0.42, 0.0, 0.0), "lower_leg_l": (0.42, 0.0, 0.0), "upper_arm_r": (-0.92, 0.0, 0.0), "upper_arm_l": (-0.92, 0.0, 0.0)}),
    (15, {"hips": (0.0, 0.0, 0.055), "spine": (-0.08, 0.0, 0.0), "upper_leg_r": (-0.16, 0.0, 0.0), "upper_leg_l": (-0.16, 0.0, 0.0), "lower_leg_r": (0.38, 0.0, 0.0), "lower_leg_l": (0.38, 0.0, 0.0), "upper_arm_r": (-0.88, 0.0, 0.0), "upper_arm_l": (-0.88, 0.0, 0.0)}),
    (20, {"hips": (0.0, 0.0, -0.03), "upper_leg_r": (0.34, 0.0, 0.0), "upper_leg_l": (0.34, 0.0, 0.0), "lower_leg_r": (-0.55, 0.0, 0.0), "lower_leg_l": (-0.55, 0.0, 0.0), "upper_arm_r": (-0.22, 0.0, 0.0), "upper_arm_l": (-0.22, 0.0, 0.0)}),
    (25, {}),
], False)

attack = create_action("Attack", [
    (1, {}),
    (4, {"hips": (0.0, 0.12, 0.0), "spine": (0.0, 0.0, 0.12), "chest": (0.0, 0.0, 0.22), "upper_arm_r": (-0.85, 0.0, 0.35), "lower_arm_r": (0.65, 0.0, 0.0)}),
    (8, {"hips": (0.0, -0.14, 0.0), "spine": (0.0, 0.0, -0.18), "chest": (0.0, 0.0, -0.32), "upper_arm_r": (0.85, 0.0, -0.55), "lower_arm_r": (-0.9, 0.0, 0.0)}),
    (12, {"hips": (0.0, -0.08, 0.0), "chest": (0.0, 0.0, -0.16), "upper_arm_r": (0.35, 0.0, -0.25), "lower_arm_r": (-0.35, 0.0, 0.0)}),
    (16, {}),
], False)

# Put all imported and authored actions on separate NLA tracks so Godot receives
# independent Idle, Walk, Run, Jump and Attack clips in one GLB.
for action in list(bpy.data.actions):
    if action.name.startswith("Armature|"):
        action.name = action.name.split("|")[-1]
armature.animation_data.action = None
for track in list(armature.animation_data.nla_tracks):
    armature.animation_data.nla_tracks.remove(track)

seen = set()
for action in list(bpy.data.actions):
    if action.name in seen:
        continue
    seen.add(action.name)
    track = armature.animation_data.nla_tracks.new()
    track.name = action.name
    start = int(action.frame_range[0])
    track.strips.new(action.name, start, action)

bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = 49
bpy.context.scene.render.fps = 24

bpy.ops.object.select_all(action="DESELECT")
for obj in meshes:
    obj.select_set(True)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
bpy.ops.export_scene.gltf(
    filepath=output_path,
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_nla_strips=True,
)
print("HERO_ANIMATED_EXPORT_OK", len(meshes), "meshes", len(armature.data.bones), "bones", sorted(seen))
