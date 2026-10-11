extends CharacterBody3D
@export var move_speed: float = 2
@export var acceleration: float = 5
@export var jump_velocity: float = 4.5
@export var reach_distance: float = 4.0 # distancia para clavar o recoger la espada

@export var tilt_intensity: float = 0.08
@export var tilt_recovery: float = 9
@export var trajectory_tilt: float = 0.6

@export var min_pivot_length: float = 1.0 # distancia para pivotear
@export var boost_inicial: float = 3.0 # fuerza con la que "salta"
@export var pivot_gravity: float = 0.6 # gravedad se reduce al pivotear
@export var pivot_push: float = 8.0 # cuanto se puede empujar en el pivote

#Velocidad con la que el modelo rota, esta rotación es para donde mira el personaje al caminar
@export var turn_speed: float = 6.0

var has_sword: bool = true
var active_sword_instance: Node3D = null

var is_moving: bool = false
var sword_sway: Vector2 = Vector2.ZERO

var is_pivot: bool = false
var pivot_point: Vector3 =Vector3.ZERO
var pivot_length: float = 0.0
var pivot_time: float = 0.0
var pivot_sword: Transform3D

#Modelos 
@onready var sword: Node3D = $sword
@onready var model: Node3D = $Model

#Componentes de animacion, junto a playback, un parametro de AnimationTree para cambiar de estados
#en la maquina de estados
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var animation_tree: AnimationTree = $Model/AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

#Estados de la maquina de estados 
enum State { IDLE, WALK, JUMP, FALL }
var state: State = State.IDLE

const swoooord = preload("res://sword_platform.tscn")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_tree.active = true
	
func _input(event):
	if has_sword and not is_pivot and event is InputEventMouseMotion:
		sword.rotation.y -= event.relative.x * 0.01
		sword.rotation.x = clamp(
			# para que no atraviese el sueloooo
			sword.rotation.x - event.relative.y * 0.01,
			deg_to_rad(-150),
			deg_to_rad(150)
		)
		
		sword_sway.x += event.relative.x * tilt_intensity * 0.05
		sword_sway.y += event.relative.y * tilt_intensity * 0.05

	# clavar y recoger la espadaa
	if event.is_action_pressed("throw") and not is_pivot:
		if has_sword:
			throw_sword()
		else:
			retrieve_sword()

	# pivoteaar
	if event.is_action_pressed("pivot"):
		if is_pivot:
			stop_pivot()
		elif has_sword:
			start_pivot()


func _physics_process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	#print("Mouse pos: ", mouse_pos)

	if is_pivot:
		pivott(delta)
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		set_state(State.JUMP)

	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var direction: Vector2 = move_input.rotated(-rotation.y)
	var target: Vector2 = direction * move_speed
	var current: Vector2 = Vector2(velocity.x, velocity.z)
	var result: Vector2 = current.move_toward(target, acceleration * delta)

	var stumble: Vector3 = Vector3.ZERO
	if move_input.length() > 0.1:
		var dir := Vector3(direction.x, 0.0, direction.y)
		var target_yaw := atan2(-dir.x, -dir.z)  # si tu modelo mira hacia +Z, usa atan2(dir.x, dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, turn_speed * delta)
	
	if has_sword:
		var sword_ws: Vector3 = -sword.global_transform.basis.z
		var sword_ad: Vector3 = sword.global_transform.basis.x
		stumble = ((sword_ad * sword_sway.x) + (sword_ws * -sword_sway.y)) * trajectory_tilt

	velocity.x = result.x + stumble.x
	velocity.z = result.y + stumble.z

	move_and_slide()
	update_animation_state()
	tilt(delta)

#STATE MACHINE
#logica detras de las animaciones del personaje
func set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	playback.travel(State.keys()[state].to_lower())

func update_animation_state() -> void:
	if not is_on_floor():
		# jump solo se mantiene si ya estábamos en JUMP, seguimos subiendo y no pivotamos
		if state == State.JUMP and velocity.y > 0.0 and not is_pivot:
			return
		set_state(State.FALL)
	else:
		var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		set_state(State.WALK if move_input.length() > 0.1 else State.IDLE)

# se tambalea si mueve la espada
func tilt(delta: float) -> void:
	if has_sword:
		var tilt_z: float = clamp(-sword_sway.x, -0.45, 0.45)
		var tilt_x: float = clamp(sword_sway.y, -0.45, 0.45)
	
		model.rotation.z = lerp_angle(model.rotation.z, tilt_z, 12.0 * delta)
		model.rotation.x = lerp_angle(model.rotation.x, tilt_x, 12.0 * delta)
	
		sword_sway = sword_sway.lerp(Vector2.ZERO, tilt_recovery * delta)


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


# pivtet
func start_pivot() -> void:
	var tip_local := Vector3(0, 1.25, 0)  # se puede ir cambiando el 1.25 por otros para que no quede flotando o rara
	var origin = sword.to_global(tip_local)
	var forward = sword.global_transform.basis.y.normalized()
	var target_pos = origin + (forward * reach_distance)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, target_pos)
	query.exclude = [get_rid()]

	var result = space_state.intersect_ray(query)
	print("result: ", result)

	if not result:
		print("no hay nada donde apoyar la espada")
		return

	var hit: Vector3 = result.position
	var length: float = global_position.distance_to(hit)

	if length < min_pivot_length:
		return

	pivot_point = hit
	pivot_length = length
	pivot_time = 0.0
	pivot_sword = sword.transform
	is_pivot = true

	var radial: Vector3 = (global_position - hit).normalized()
	var forward_dir: Vector3 = Vector3(-radial.x, 0.0, -radial.z).normalized()
	var run_speed: float = max(0.0, velocity.dot(forward_dir))

	var tangent_up: Vector3 = (Vector3.UP + forward_dir * 0.5)
	tangent_up = (tangent_up - radial * tangent_up.dot(radial)).normalized()

	velocity = tangent_up * (boost_inicial + run_speed)

func stop_pivot() -> void:
	is_pivot = false
	sword.transform = pivot_sword
	sword_sway = Vector2.ZERO

func pivott(delta: float) -> void:
	pivot_time += delta
	var offset: Vector3 = global_position - pivot_point

	if offset.length() < 0.01:
		stop_pivot()
		return

	var radial: Vector3 = offset.normalized()
	velocity += get_gravity() * pivot_gravity * delta
	
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir2: Vector2 = move_input.rotated(-rotation.y)
	var wish: Vector3 = Vector3(dir2.x, 0.0, dir2.y)
	var push: Vector3 = wish - radial * wish.dot(radial)

	velocity += push * pivot_push * delta
	velocity -= radial * velocity.dot(radial)
	move_and_slide()
	update_animation_state()

	var current_dist: float = global_position.distance_to(pivot_point)

	if current_dist > pivot_length:
		global_position = pivot_point + (global_position - pivot_point).normalized() * pivot_length

	if sword.global_position.distance_to(pivot_point) > 0.05:
		sword.look_at(pivot_point, Vector3.UP)
		sword.rotate_object_local(Vector3.RIGHT, -PI / 2)

	if Input.is_action_just_pressed("jump"):
		velocity += Vector3.UP * 2.0
		stop_pivot()
	elif pivot_time > 0.3 and is_on_floor():
		stop_pivot() 
