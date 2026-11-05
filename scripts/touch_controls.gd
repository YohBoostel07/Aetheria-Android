extends Control

@export var player_path: NodePath
@onready var player: CharacterBody3D = get_node(player_path)

var joystick_touch := -1
var camera_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_current := Vector2.ZERO
var joystick_radius := 82.0
var button_jump := Rect2()
var button_attack := Rect2()

func _ready() -> void:
    get_viewport().size_changed.connect(queue_redraw)
    set_process_input(true)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var size := get_viewport_rect().size
    var base := Vector2(120, size.y - 125)
    draw_circle(base, joystick_radius, Color(0.05, 0.08, 0.12, 0.30))
    draw_arc(base, joystick_radius, 0, TAU, 48, Color(0.85, 0.91, 1, 0.55), 3.0)
    var knob := joystick_current if joystick_touch != -1 else base
    draw_circle(knob, 34, Color(0.35, 0.62, 0.95, 0.72))
    button_attack = Rect2(size.x - 112, size.y - 125, 82, 82)
    button_jump = Rect2(size.x - 220, size.y - 90, 68, 68)
    draw_circle(button_attack.position + button_attack.size / 2, 41, Color(0.75, 0.23, 0.18, 0.72))
    draw_circle(button_jump.position + button_jump.size / 2, 34, Color(0.22, 0.52, 0.82, 0.72))
    draw_string(ThemeDB.fallback_font, button_attack.position + Vector2(29, 47), "ATK", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    draw_string(ThemeDB.fallback_font, button_jump.position + Vector2(18, 40), "PULO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(34, 42), "VIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    draw_rect(Rect2(34, 51, 210, 18), Color(0.04, 0.06, 0.08, 0.72), true)
    var maximum_health := maxf(1.0, float(player.get("max_health")))
    var current_health := clampf(float(player.get("health")), 0.0, maximum_health)
    var health_ratio := current_health / maximum_health
    var health_color := Color(0.2, 0.78, 0.35) if health_ratio > 0.3 else Color(0.88, 0.2, 0.16)
    draw_string(ThemeDB.fallback_font, Vector2(250, 66), "%d/%d" % [int(current_health), int(maximum_health)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
    draw_rect(Rect2(37, 54, 204.0 * health_ratio, 12), health_color, true)
    draw_rect(Rect2(34, 51, 210, 18), Color(1, 1, 1, 0.72), false, 2.0)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_pressed(event.index, event.position)
        else:
            _touch_released(event.index)
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _update_joystick(event.position)
        elif event.index == camera_touch:
            player.rotate_camera(event.relative.x, event.relative.y)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _touch_pressed(99, event.position)
    elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _touch_released(99)
    elif event is InputEventMouseMotion and camera_touch == 99:
        player.rotate_camera(event.relative.x, event.relative.y)
    elif event is InputEventMouseMotion and joystick_touch == 99:
        _update_joystick(event.position)

func _touch_pressed(index: int, pos: Vector2) -> void:
    if button_attack.has_point(pos):
        player.perform_attack()
    elif button_jump.has_point(pos):
        if player.is_on_floor():
            player.velocity.y = player.jump_velocity
    elif pos.x < get_viewport_rect().size.x * 0.48 and joystick_touch == -1:
        joystick_touch = index
        joystick_origin = Vector2(120, get_viewport_rect().size.y - 125)
        _update_joystick(pos)
    elif camera_touch == -1:
        camera_touch = index

func _touch_released(index: int) -> void:
    if index == joystick_touch:
        joystick_touch = -1
        joystick_current = joystick_origin
        player.set_touch_move(Vector2.ZERO)
        queue_redraw()
    if index == camera_touch:
        camera_touch = -1

func _update_joystick(pos: Vector2) -> void:
    var offset := (pos - joystick_origin).limit_length(joystick_radius)
    joystick_current = joystick_origin + offset
    player.set_touch_move(Vector2(offset.x / joystick_radius, offset.y / joystick_radius))
    queue_redraw()
