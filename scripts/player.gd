extends CharacterBody3D

@export var move_speed: float = 5.8
@export var acceleration: float = 18.0
@export var jump_velocity: float = 5.2
@export var camera_sensitivity: float = 0.006

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var body_mesh: Node3D = $Body
@onready var character_visual = $Body

var touch_move := Vector2.ZERO
var camera_yaw := 0.0
var camera_pitch := -0.28
var attack_cooldown := 0.0
var health := 100
var is_dead := false
var respawn_position := Vector3(0, 1.2, 4)

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    camera_yaw = rotation.y
    respawn_position = global_position

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if touch_move.length() > 0.12:
        input_vector = touch_move
    var camera_basis := Basis(Vector3.UP, camera_yaw)
    var direction := camera_basis * Vector3(input_vector.x, 0, input_vector.y)
    direction.y = 0
    direction = direction.normalized()

    if direction.length() > 0.05:
        velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
        body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, atan2(-direction.x, -direction.z), 12.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

    if not is_on_floor():
        velocity.y -= 9.8 * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity

    if Input.is_action_just_pressed("attack"):
        perform_attack()
    move_and_slide()
    character_visual.animate_character(delta, Vector2(velocity.x, velocity.z).length(), not is_on_floor())

func set_touch_move(value: Vector2) -> void:
    touch_move = value.limit_length(1.0)

func rotate_camera(delta_x: float, delta_y: float) -> void:
    camera_yaw -= delta_x * camera_sensitivity
    camera_pitch = clampf(camera_pitch - delta_y * camera_sensitivity, -0.85, 0.15)
    spring_arm.rotation = Vector3(camera_pitch, camera_yaw, 0)

func perform_attack() -> void:
    if is_dead or attack_cooldown > 0.0:
        return
    attack_cooldown = 0.55
    character_visual.play_attack()
    var sphere := SphereShape3D.new()
    sphere.radius = 1.55
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = sphere
    query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.95 + (-global_basis.z * 1.05))
    query.exclude = [get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = false
    for hit in get_world_3d().direct_space_state.intersect_shape(query, 12):
        var target := hit.get("collider") as Node
        if target != null and target.is_in_group("enemies") and target.has_method("take_damage"):
            target.take_damage(30)

func take_damage(amount: int) -> void:
    if is_dead or amount <= 0:
        return
    health = maxi(0, health - amount)
    if health == 0:
        is_dead = true
        velocity = Vector3.ZERO
        await get_tree().create_timer(1.2).timeout
        global_position = respawn_position
        velocity = Vector3.ZERO
        health = 100
        is_dead = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_camera(event.relative.x, event.relative.y)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
