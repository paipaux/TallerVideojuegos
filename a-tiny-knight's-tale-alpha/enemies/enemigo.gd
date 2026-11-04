extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

@export var speed: float = 1.0 # Velocidad de movimiento del enemigo
@export var detection: float = 8.0 # distancia en la que el enemigo empieza a perseguir
@export var lose_range: float = 12.0 # distancia en la que el enemigo deja de perseguir
@export var recoil: float = 3.0 # al pegarle retrocede levemente

var player: Node3D = null
var chasing: bool = false


func _ready() -> void:
	health_component.died.connect(_on_died)
	hurtbox_component.hurt.connect(_on_hurt)

	# se busca al jugador
	player = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta: float) -> void:
	# añadimos gravedad
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	_update_chase()

	var target: Vector3 = Vector3.ZERO

	if chasing and player:
		# se calcula la dirección hacia el jugador
		var direction = player.global_position - global_position
		direction.y = 0.0

		if direction.length() > 0.1:
			target = direction.normalized() * speed

			# hacemps que el enemigo mire hacia el jugador
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	velocity.x = move_toward(velocity.x, target.x, 10.0 * delta)
	velocity.z = move_toward(velocity.z, target.z, 10.0 * delta)

	# se mueve el personaje usando las físicas de Godot
	move_and_slide()


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


func _on_hurt(hitbox: HitboxComponent) -> void:
	var away := global_position - hitbox.global_position
	away.y = 0.0

	if away.length() > 0.01:
		velocity += away.normalized() * recoil

	chasing = true


func _on_died() -> void:
	queue_free()
