extends CharacterBody3D
@export var move_speed: float = 2
@export var acceleration: float = 5


var is_moving: bool = false


@onready var sword: Node3D = $sword

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		sword.rotation.y -= event.relative.x * 0.01
		sword.rotation.x -= event.relative.y * 0.01


func _physics_process(delta: float) -> void:
	
	var mouse_pos = get_viewport().get_mouse_position()
	print("Mouse pos: ", mouse_pos)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var direction: Vector2 = move_input.rotated(-rotation.y)
	var target: Vector2 = direction * move_speed
	var current: Vector2 = Vector2(velocity.x, velocity.z)
	var result: Vector2 = current.move_toward(target, acceleration * delta)

	velocity.x = result.x
	velocity.z = result.y

	move_and_slide()
