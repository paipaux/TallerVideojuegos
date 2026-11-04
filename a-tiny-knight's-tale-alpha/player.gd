extends CharacterBody3D
@export var move_speed: float = 2
@export var acceleration: float = 5
@export var jump_velocity: float = 4.5
@export var reach_distance: float = 4.0 # distancia para clavar o recoger la espada

# Espada con peso, Modificar para buscar buen movimiento

@export var mouse_sensitivity: float = 0.003 # radianes de impulso por pixel de mouse
@export var mouse_boost_max: float = 1.5    # multiplicador del impulso tras mover el mouse sostenidamente
@export var sword_accel_ramp: float = 0.5   # segundos moviendo en la misma dirección para llegar al boost máximo
@export var mouse_idle_grace: float = 0.10  # segundos sin mover el mouse antes de perder el boost
@export var sword_max_speed: float = 4.0    # velocidad angular máxima 
@export var sword_damping: float = 0.5   # qué tan rápido se frena al dejar de mover el mouse

@export var tilt_intensity: float = 0.08
@export var tilt_recovery: float = 9
@export var trajectory_tilt: float = 0.6

#Variables de movimiento de la espada
#Se usan para guardar la orientación de la espada de modo que no se
#voltee y altere de ese modo su movimiento (arregla error clamp)

var sword_yaw: float = 0.0
var sword_pitch: float = 0.0
@onready var sword_cast: ShapeCast3D = $sword/ShapeCast3D #Detecta si la espada choca con el "mundo"

#Variables para poder deslizar la espada si traspasa el "mundo" al mover personaje
#Necesario ya que en caso contrario solo se calcula posición al mover espada estando en el suelo
@export var sword_settle_speed: float = 5.0      # rad/s con que la espada sale de lo que atraviesa (+ alto sale más rápido)
@export var sword_settle_step_deg: float = 0.5    # precisión de la búsqueda (menor = más preciso, más costoso)
@export var sword_settle_max_deg: float = 120.0   # hasta qué ángulo busca una pose libre


#Variables de Pivote

@export var min_pivot_length: float = 1.0 # distancia para pivotear
@export var boost_inicial: float = 2.5 # fuerza con la que "salta"
@export var pivot_gravity: float = 0.6 # gravedad se reduce al pivotear
@export var pivot_push: float = 6.0 # cuanto se puede empujar en el pivote

#Velocidad con la que el modelo rota, esta rotación es para donde mira el personaje al caminar
@export var turn_speed: float = 6.0

var has_sword: bool = true
var active_sword_instance: Node3D = null

var is_moving: bool = false
var sword_sway: Vector2 = Vector2.ZERO
var sword_vel: Vector2 = Vector2.ZERO  # x = giro horizontal, y = giro vertical
var aim_hold: Vector2 = Vector2.ZERO   # segundos que llevas moviendo el mouse en cada eje
var aim_idle: Vector2 = Vector2.ZERO   # segundos sin mover el mouse en cada eje
var mouse_input: Vector2 = Vector2.ZERO # movimiento acumulado del mouse entre ticks de física

var is_pivot: bool = false
var pivot_point: Vector3 = Vector3.ZERO
var pivot_length: float = 0.0
var pivot_time: float = 0.0

#Modelos 
@onready var sword: Node3D = $sword
@onready var model: Node3D = $Model

#Componentes de animacion, junto a playback, un parametro de AnimationTree para cambiar de estados
#en la maquina de estados
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var animation_tree: AnimationTree = $Model/AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var two_bone_ik_3d: TwoBoneIK3D = $Model/TheHero/Skeleton3D/TwoBoneIK3D

#Estados de la maquina de estados (animacion) 
enum State { IDLE, WALK, JUMP, FALL }
var state: State = State.IDLE

const swoooord = preload("res://sword_platform.tscn")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_tree.active = true #activar animation tree
	sword_yaw = sword.rotation.y #Iniciar yaw y pitch para mov. espada
	sword_pitch = sword.rotation.x
	sword_cast.add_exception(self) #Iniciar cast espada para que no traspase el "mundo"
	
func _input(event):
	# el mouse no mueve la espada directo, solo le da impulso (se consume en update_sword_aim)
	if has_sword and not is_pivot and event is InputEventMouseMotion:
		mouse_input += event.relative

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

#Prueba si la espada choca con el "mundo" usando el cast
#Devuelve True si es así (mov.ilegal)
func _sword_hits(pitch: float, yaw: float) -> bool:
	sword.rotation = Vector3(pitch, yaw, 0.0)
	sword_cast.force_shapecast_update()
	return sword_cast.is_colliding()

const SETTLE_DIRS: Array[Vector2] = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]

# Busca la pose libre más cercana y rota hacia ella. Devuelve false si no encontró ninguna.
func _settle_sword(delta: float) -> bool:
	var step: float = deg_to_rad(sword_settle_step_deg)
	var max_angle: float = deg_to_rad(sword_settle_max_deg)
	var angle: float = step

	while angle <= max_angle:
		for d in SETTLE_DIRS:
			var target_pitch: float = sword_pitch + d.x * angle
			var target_yaw: float = sword_yaw + d.y * angle
			if not _sword_hits(target_pitch, target_yaw):
				var max_step: float = sword_settle_speed * delta
				sword_pitch = move_toward(sword_pitch, target_pitch, max_step)
				sword_yaw = move_toward(sword_yaw, target_yaw, max_step)
				sword_vel = Vector2.ZERO
				return true
		angle += step

	return false

# Movimiento de la espada con mouse: el mouse da impulso a una velocidad angular con inercia
func update_sword_aim(delta: float) -> void:
	if not has_sword:
		sword_vel = Vector2.ZERO
		aim_hold = Vector2.ZERO
		aim_idle = Vector2.ZERO
		mouse_input = Vector2.ZERO
		return

	for axis in 2:
		if absf(mouse_input[axis]) > 0.0:
			# mientras más tiempo sigas moviendo el mouse, más fuerte es el impulso
			aim_hold[axis] += delta
			aim_idle[axis] = 0.0
			var t: float = clampf(aim_hold[axis] / sword_accel_ramp, 0.0, 1.0)
			var boost: float = lerpf(1.0, mouse_boost_max, t * t)
			sword_vel[axis] += mouse_input[axis] * mouse_sensitivity * boost
		else:
			# sin movimiento: tras un instante se pierde el boost y la inercia se apaga
			aim_idle[axis] += delta
			if aim_idle[axis] > mouse_idle_grace:
				aim_hold[axis] = 0.0
			sword_vel[axis] = lerpf(sword_vel[axis], 0.0, sword_damping * delta)

	mouse_input = Vector2.ZERO

	sword_vel = sword_vel.limit_length(sword_max_speed)

	# aplicar la rotación probando colisión por eje
	# 1) si la espada quedó dentro de algo (salto, caída, caminar), se acomoda sola
	var hitting: bool = _sword_hits(sword_pitch, sword_yaw)
	var settling: bool = false
	if hitting:
		settling = _settle_sword(delta)
	
	# 2) si no se está acomodando, el mouse la mueve probando colisión por eje
	if not settling:

		# yaw, se calcula rotación respecto al eje y de la espada 
		# ej. decir que "no" con la cabeza
		var new_yaw: float = sword_yaw - sword_vel.x * delta
		if not hitting and _sword_hits(sword_pitch, new_yaw):
			sword_vel.x = 0.0
		else:
			sword_yaw = wrapf(new_yaw, -PI, PI)

		# pitch, se calcula rotación respecto al eje x de la espada
		# ej. decir que "si" con la cabeza
		var new_pitch: float = sword_pitch - sword_vel.y * delta
		if not hitting and _sword_hits(new_pitch, sword_yaw):
			sword_vel.y = 0.0
		else:
			sword_pitch = wrapf(new_pitch, -PI, PI)
	
	#Aplicar movimiento calculado de la espada
	sword.rotation = Vector3(sword_pitch, sword_yaw, 0.0)


func _physics_process(delta: float) -> void:
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
	update_sword_aim(delta)
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
		
# SETEAR ANIMACION BRAZOS
func set_arm_ik(value: float) -> void:
	var tween = create_tween()
	tween.tween_property(two_bone_ik_3d, "influence", value, 0.2)

# se tambalea si mueve la espada
# Se tambalea si mueve la espada y recupera la postura al lanzarla
func tilt(delta: float) -> void:
	if has_sword:
		var tilt_z: float = clamp(-sword_sway.x, -0.45, 0.45)
		var tilt_x: float = clamp(sword_sway.y, -0.45, 0.45)

		model.rotation.z = lerp_angle(model.rotation.z, tilt_z, 12.0 * delta)
		model.rotation.x = lerp_angle(model.rotation.x, tilt_x, 12.0 * delta)

	else:
		# Recuperar la postura original
		model.rotation.z = lerp_angle(model.rotation.z, 0.0, 8.0 * delta)
		model.rotation.x = lerp_angle(model.rotation.x, 0.0, 8.0 * delta)

	# Recuperar gradualmente el sway
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

	# si la espada esta en el boton
	var btn = result.collider
	
	if btn and btn.has_method("on_sword_pressed"):
		btn.on_sword_pressed(embedded_sword)

	sword.visible = false
	has_sword = false
	active_sword_instance = embedded_sword
	sword_vel = Vector2.ZERO
	aim_hold = Vector2.ZERO
	set_arm_ik(0.0) #hacer que brazos no sigan espada
	
# recoger la espada
func retrieve_sword() -> void:
	if active_sword_instance and is_instance_valid(active_sword_instance):
		var dist = global_position.distance_to(active_sword_instance.global_position)
		if dist <= reach_distance:
			active_sword_instance.queue_free()
			active_sword_instance = null
			sword.visible = true
			has_sword = true
			set_arm_ik(1.0) #brazos siguen espada


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
	is_pivot = true

	var radial: Vector3 = (global_position - hit).normalized()
	var forward_dir: Vector3 = Vector3(-radial.x, 0.0, -radial.z).normalized()
	var run_speed: float = max(0.0, velocity.dot(forward_dir))

	var tangent_up: Vector3 = (Vector3.UP + forward_dir * 0.5)
	tangent_up = (tangent_up - radial * tangent_up.dot(radial)).normalized()

	velocity = tangent_up * (boost_inicial + run_speed)

func stop_pivot() -> void:
	is_pivot = false
	sword.rotation = Vector3(sword_pitch, sword_yaw, 0.0)
	sword_sway = Vector2.ZERO
	sword_vel = Vector2.ZERO
	aim_hold = Vector2.ZERO
	aim_idle = Vector2.ZERO
	mouse_input = Vector2.ZERO

#OJOOO REVISAR MÁS ADELANTE, DSP DE PIVOT ESPADA SE RESETEA A POSICION ORIGINAL
#ESTO SE DEBE A LOS CAMBIOS HECHOS PARA ARREGLAR CLAMP
#OJALÁ REWORK DE PIVOT SI SE PUEDE
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
