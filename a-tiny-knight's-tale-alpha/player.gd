extends CharacterBody3D
@export var move_speed: float = 2
@export var acceleration: float = 5
@export var jump_velocity: float = 4.5
@export var reach_distance: float = 4.0 # distancia para clavar o recoger la espada

var has_sword: bool = true
var active_sword_instance: Node3D = null

var is_moving: bool = false


@onready var sword: Node3D = $sword

const swoooord = preload("res://sword_platform.tscn")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		sword.rotation.y -= event.relative.x * 0.01
		sword.rotation.x = clamp(
			# para que no atraviese el sueloooo
			sword.rotation.x - event.relative.y * 0.01,
			deg_to_rad(-90),
			deg_to_rad(90)
		)
	
	# clavar y recoger la espadaa
	if event.is_action_pressed("throw"):
		if has_sword:
			throw_sword()
		else:
			retrieve_sword()


func _physics_process(delta: float) -> void:
	
	var mouse_pos = get_viewport().get_mouse_position()
	print("Mouse pos: ", mouse_pos)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var direction: Vector2 = move_input.rotated(-rotation.y)
	var target: Vector2 = direction * move_speed
	var current: Vector2 = Vector2(velocity.x, velocity.z)
	var result: Vector2 = current.move_toward(target, acceleration * delta)

	velocity.x = result.x
	velocity.z = result.y

	move_and_slide()

func throw_sword() -> void:
	var tip_local := Vector3(0, 1.25, 0)  # se puede ir cambiando el 1.25 por otros para que no quede flotando o rara
	var origin = sword.to_global(tip_local)
	var forward = sword.global_transform.basis.y.normalized()
	var target_pos = origin + (forward * reach_distance)

	print("origin: ", origin, " | forward: ", forward, " | target_pos: ", target_pos)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, target_pos)
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result = space_state.intersect_ray(query)
	print("result: ", result)

	if not result:
		print("no hay nada donde clavar la espada")
		return

	var hit_position: Vector3 = result.position

	var embedded_sword = swoooord.instantiate()
	get_tree().current_scene.add_child(embedded_sword)

	embedded_sword.global_transform = sword.global_transform
	embedded_sword.global_position = hit_position

	sword.visible = false
	has_sword = false
	active_sword_instance = embedded_sword

# recoger la espada
func retrieve_sword() -> void:
	if active_sword_instance and is_instance_valid(active_sword_instance):
		var dist = global_position.distance_to(active_sword_instance.global_position)
		if dist <= reach_distance:
			active_sword_instance.queue_free()
			active_sword_instance = null
			sword.visible = true
			has_sword = true
