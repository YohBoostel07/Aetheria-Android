import bpy
import math
import sys

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

bones = {
    "hips": find_bone("hips"),
    "spine": find_bone("spine"),
    "chest": find_bone("chest") or find_bone("spine2"),
    "head": find_bone("head"),
    "upper_arm_r": find_bone("upperarm", "r") or find_bone("right", "upperarm"),
    "lower_arm_r": find_bone("lowerarm", "r") or find_bone("right", "lowerarm"),
    "upper_arm_l": find_bone("upperarm", "l") or find_bone("left", "upperarm"),
    "lower_arm_l": find_bone("lowerarm", "l") or find_bone("left", "lowerarm"),
    "upper_leg_r": find_bone("upperleg", "r") or find_bone("right", "upperleg"),
    "lower_leg_r": find_bone("lowerleg", "r") or find_bone("right", "lowerleg"),
    "upper_leg_l": find_bone("upperleg", "l") or find_bone("left", "upperleg"),
    "lower_leg_l": find_bone("lowerleg", "l") or find_bone("left", "lowerleg"),
}
print("HERO_RIG_BONES", bones)
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
