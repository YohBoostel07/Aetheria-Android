import bpy
import math
import sys
from mathutils import Vector, Matrix

args = sys.argv[sys.argv.index("--") + 1:]
source_path, output_path = args[0], args[1]

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source_path)

meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if not meshes:
    raise RuntimeError("Sombrio GLB contains no mesh objects")

corners = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
minimum = Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
maximum = Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
height = maximum.z - minimum.z
width = maximum.x - minimum.x
if height <= 0.1 or width <= 0.05:
    raise RuntimeError("Invalid Sombrio model bounds")
cx = (minimum.x + maximum.x) * 0.5
cy = (minimum.y + maximum.y) * 0.5
z0 = minimum.z
# Coordinates are estimated from the scanned biped silhouette and scaled to its bounds.
def P(x, z, y=None):
    return (cx + x * width, cy if y is None else y, z0 + z * height)

arm_data = bpy.data.armatures.new("SombrioRig")
arm_obj = bpy.data.objects.new("SombrioRig", arm_data)
bpy.context.collection.objects.link(arm_obj)
bpy.context.view_layer.objects.active = arm_obj
arm_obj.select_set(True)
for obj in meshes:
    obj.select_set(False)
bpy.ops.object.mode_set(mode="EDIT")

bones = {}
def bone(name, head, tail, parent=None, connected=False):
    b = arm_data.edit_bones.new(name)
    b.head = head
    b.tail = tail
    if parent:
        b.parent = bones[parent]
        b.use_connect = connected
    bones[name] = b

bone("Root", P(0, 0.03), P(0, 0.12))
bone("Hips", P(0, 0.43), P(0, 0.54), "Root")
bone("Spine", P(0, 0.54), P(0, 0.70), "Hips", True)
bone("Chest", P(0, 0.70), P(0, 0.79), "Spine", True)
bone("Neck", P(0, 0.79), P(0, 0.86), "Chest", True)
bone("Head", P(0, 0.86), P(0, 0.98), "Neck", True)
for side, suffix in [(-1, ".L"), (1, ".R")]:
    hip_x = side * 0.105
    knee_x = side * 0.12
    ankle_x = side * 0.12
    shoulder_x = side * 0.18
    elbow_x = side * 0.34
    wrist_x = side * 0.43
    bone("UpperLeg" + suffix, P(hip_x, 0.48), P(knee_x, 0.25), "Hips")
    bone("LowerLeg" + suffix, P(knee_x, 0.25), P(ankle_x, 0.07), "UpperLeg" + suffix, True)
    bone("Foot" + suffix, P(ankle_x, 0.07), P(ankle_x, 0.035, cy - height * 0.08), "LowerLeg" + suffix, True)
    bone("UpperArm" + suffix, P(shoulder_x, 0.76), P(elbow_x, 0.62), "Chest")
    bone("LowerArm" + suffix, P(elbow_x, 0.62), P(wrist_x, 0.49), "UpperArm" + suffix, True)
    bone("Hand" + suffix, P(wrist_x, 0.49), P(wrist_x, 0.43), "LowerArm" + suffix, True)

bpy.ops.object.mode_set(mode="OBJECT")

# Bind the scanned mesh with distance-based smooth weights. This avoids
# Blender heat-weight failures on dense scanned geometry and disconnected claws.
def point_segment_distance(point, start, end):
    segment = end - start
    length_squared = segment.length_squared
    if length_squared < 1e-10:
        return (point - start).length
    factor = max(0.0, min(1.0, (point - start).dot(segment) / length_squared))
    return (point - (start + segment * factor)).length

bone_segments = []
for data_bone in arm_data.bones:
    bone_segments.append((data_bone.name, data_bone.head_local.copy(), data_bone.tail_local.copy()))

for obj in meshes:
    # Bake imported object transforms so vertices and skeleton share one space.
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    obj.parent = arm_obj
    modifier = obj.modifiers.new("Sombrio skeletal deformation", "ARMATURE")
    modifier.object = arm_obj

    groups = {name: obj.vertex_groups.new(name=name) for name, _, _ in bone_segments}
    for vertex in obj.data.vertices:
        point = vertex.co
        ranked = []
        for name, head, tail in bone_segments:
            distance = point_segment_distance(point, head, tail)
            ranked.append((distance, name))
        ranked.sort(key=lambda item: item[0])
        nearest = ranked[:3]
        weights = [1.0 / max(distance, 0.035) ** 2.0 for distance, _ in nearest]
        total = sum(weights)
        for weight, (_, name) in zip(weights, nearest):
            groups[name].add([vertex.index], weight / total, "REPLACE")

# Create an actual alternating biped gait (legs, arms and counter-rotating torso).
bpy.context.view_layer.objects.active = arm_obj
arm_obj.select_set(True)
bpy.ops.object.mode_set(mode="POSE")
for pb in arm_obj.pose.bones:
    pb.rotation_mode = "XYZ"

walk = bpy.data.actions.new("Walk")
arm_obj.animation_data_create()
arm_obj.animation_data.action = walk
for frame, phase in [(1, 0.0), (7, math.pi * 0.5), (13, math.pi), (19, math.pi * 1.5), (25, math.tau)]:
    for side, suffix in [(-1, ".L"), (1, ".R")]:
        swing = math.sin(phase) * 0.48 * side
        arm_obj.pose.bones["UpperLeg" + suffix].rotation_euler.x = swing
        arm_obj.pose.bones["LowerLeg" + suffix].rotation_euler.x = max(0.0, -math.sin(phase) * 0.55)
        arm_obj.pose.bones["UpperArm" + suffix].rotation_euler.x = -swing * 0.72
        arm_obj.pose.bones["LowerArm" + suffix].rotation_euler.x = -0.12
        for name in ["UpperLeg" + suffix, "LowerLeg" + suffix, "UpperArm" + suffix, "LowerArm" + suffix]:
            arm_obj.pose.bones[name].keyframe_insert(data_path="rotation_euler", frame=frame, group=name)
    arm_obj.pose.bones["Spine"].rotation_euler.x = math.sin(phase * 2.0) * 0.025
    arm_obj.pose.bones["Hips"].location.z = abs(math.sin(phase)) * 0.018
    arm_obj.pose.bones["Spine"].keyframe_insert(data_path="rotation_euler", frame=frame, group="Spine")
    arm_obj.pose.bones["Hips"].keyframe_insert(data_path="location", frame=frame, group="Hips")

for fc in walk.fcurves:
    for key in fc.keyframe_points:
        key.interpolation = "BEZIER"
    fc.modifiers.new("CYCLES")
walk.use_fake_user = True

# A restrained idle keeps the creature alive when it is not pursuing the player.
idle = bpy.data.actions.new("Idle")
arm_obj.animation_data.action = idle
for frame, phase in [(1, 0.0), (7, math.pi * 0.5), (13, math.pi), (19, math.pi * 1.5), (25, math.tau)]:
    for pb in arm_obj.pose.bones:
        pb.rotation_euler = (0.0, 0.0, 0.0)
    arm_obj.pose.bones["Spine"].rotation_euler.x = math.sin(phase) * 0.018
    arm_obj.pose.bones["Chest"].rotation_euler.x = math.sin(phase) * 0.012
    arm_obj.pose.bones["Head"].rotation_euler.z = math.sin(phase * 0.5) * 0.018
    arm_obj.pose.bones["Hips"].rotation_euler.z = math.sin(phase) * 0.012
    for pb in arm_obj.pose.bones:
        pb.keyframe_insert(data_path="rotation_euler", frame=frame, group=pb.name)
for fc in idle.fcurves:
    for key in fc.keyframe_points:
        key.interpolation = "BEZIER"
    fc.modifiers.new("CYCLES")
idle.use_fake_user = True

# A two-arm claw strike: wind-up, forward slash, follow-through and recovery.
attack = bpy.data.actions.new("Attack")
arm_obj.animation_data.action = attack
for frame, upper_r, lower_r, upper_l, lower_l, torso in [
    (1, 0.0, 0.0, 0.0, 0.0, 0.0),
    (4, -0.85, 0.45, -0.45, 0.25, 0.18),
    (8, 0.95, -0.95, 0.55, -0.65, -0.28),
    (12, 0.35, -0.35, 0.15, -0.2, -0.12),
    (16, 0.0, 0.0, 0.0, 0.0, 0.0),
]:
    for pb in arm_obj.pose.bones:
        pb.rotation_euler = (0.0, 0.0, 0.0)
    arm_obj.pose.bones["UpperArm.R"].rotation_euler.x = upper_r
    arm_obj.pose.bones["LowerArm.R"].rotation_euler.x = lower_r
    arm_obj.pose.bones["UpperArm.L"].rotation_euler.x = upper_l
    arm_obj.pose.bones["LowerArm.L"].rotation_euler.x = lower_l
    arm_obj.pose.bones["Chest"].rotation_euler.z = torso
    arm_obj.pose.bones["Spine"].rotation_euler.z = torso * 0.6
    for pb in arm_obj.pose.bones:
        pb.keyframe_insert(data_path="rotation_euler", frame=frame, group=pb.name)
for fc in attack.fcurves:
    for key in fc.keyframe_points:
        key.interpolation = "BEZIER"
attack.use_fake_user = True

# Export the three independent animation clips as NLA tracks for Godot.
arm_obj.animation_data.action = None
for track in list(arm_obj.animation_data.nla_tracks):
    arm_obj.animation_data.nla_tracks.remove(track)
for action in [walk, idle, attack]:
    track = arm_obj.animation_data.nla_tracks.new()
    track.name = action.name
    track.strips.new(action.name, int(action.frame_range[0]), action)

bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = 25
bpy.context.scene.render.fps = 24
bpy.ops.object.mode_set(mode="OBJECT")

# Export only the model and rig, with the walk action embedded in the GLB.
bpy.ops.object.select_all(action="DESELECT")
for obj in meshes:
    obj.select_set(True)
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.export_scene.gltf(
    filepath=output_path,
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_nla_strips=True,
    export_force_sampling=True,
)
print("RIGGED_SOMBRIO_OK", len(meshes), "meshes", len(arm_data.bones), "bones", output_path)
