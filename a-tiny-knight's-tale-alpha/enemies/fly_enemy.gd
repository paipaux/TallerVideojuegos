extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

@export var speed: float = 1.5 # Velocidad de movimiento del enemigo
@export var detection: float = 10.0# distancia en la que el enemigo empieza a perseguir
@export var lose_range: float = 20.0 # distancia en la que el enemigo deja de perseguir
@export var recoil: float = 3.0 # al pegarle retrocede levemente
@export var over_player: float = 0.1 # altura sobre el jugador se pone
@export var acceleration: float = 10.0

#animaciones
@onready var animation_tree: AnimationTree = $Model/BatEnemy/AnimationTree
var state_machine: AnimationNodeStateMachinePlayback
#Tiempo antes de ejecutar proxima animacion de daño (no se sobrelapan golpes consecutivos)
@export var damage_duration: float = 0.5
var damage_timer_id: int = 0 
var taking_damage: bool = false

var player: Node3D = null
var chasing: bool = false


func _ready() -> void:
	health_component.died.connect(_on_died)
	hurtbox_component.hurt.connect(_on_hurt)
	
	state_machine = animation_tree.get("parameters/playback")
	state_machine.state_finished.connect(_on_animation_state_finished)

	# se busca al jugador
	player = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta: float) -> void:
	# no hay gravedad!!
	_update_chase()

	var target: Vector3 = Vector3.ZERO

	if chasing and player:
		# se calcula la dirección hacia el jugador
		# apunta a la cabeza del jugador (no sus pies)
		var direction = (player.global_position + Vector3.UP * over_player) - global_position

		if direction.length() > 0.1:
			target = direction.normalized() * speed

		var looking := player.global_position - global_position
		looking.y = 0.0

		if looking.length() > 0.1:
			# hacemps que el enemigo mire hacia el jugador
			look_at(global_position + looking, Vector3.UP)

	velocity = velocity.move_toward(target, acceleration * delta)

	# se mueve el personaje usando las físicas de Godot
	move_and_slide()
	_update_movement_animation()


func _update_chase() -> void:
	if not player:
		chasing = false
		return

	var distancia := global_position.distance_to(player.global_position)

	if chasing:
		if distancia <= lose_range:
			chasing = true
		else:
			chasing = false
	else:
		if distancia <= detection:
			chasing = true
		else:
			chasing = false

func _on_animation_state_finished(state: StringName) -> void:
	if state == "attack":
		_update_animation_state()

func _on_hurt(hitbox: HitboxComponent) -> void:
	var away := global_position - hitbox.global_position

	if away.length() > 0.01:
		velocity += away.normalized() * recoil

	chasing = true

	taking_damage = true
	state_machine.travel("damage")

	damage_timer_id += 1
	var current_timer := damage_timer_id

	await get_tree().create_timer(damage_duration).timeout

	if current_timer != damage_timer_id:
		return

	taking_damage = false
	_update_animation_state()

func _update_animation_state() -> void:
	if chasing:
		state_machine.travel("fly")
	else:
		state_machine.travel("idle")
		

func _update_movement_animation() -> void:
	if taking_damage:
		return

	if state_machine.get_current_node() == "attack":
		return

	if velocity.length() > 0.1:
		state_machine.travel("fly")
	else:
		state_machine.travel("idle")

func _on_died() -> void:
	queue_free()
