extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

@export var speed: float = 1.0
@export var detection: float = 8.0
@export var lose_range: float = 12.0
@export var recoil: float = 3.0

var player: Node3D = null
var chasing: bool = false


func _ready() -> void:
	health_component.died.connect(_on_died)
	hurtbox_component.hurt.connect(_on_hurt)

	player = get_tree().get_first_node_in_group("jugador")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	_update_chase()

	var target: Vector3 = Vector3.ZERO

	if chasing and player:
		var direction = player.global_position - global_position
		direction.y = 0.0

		if direction.length() > 0.1:
			target = direction.normalized() * speed

			look_at(
				Vector3(
					player.global_position.x,
					global_position.y,
					player.global_position.z
				),
				Vector3.UP
			)

	velocity.x = move_toward(velocity.x, target.x, 10.0 * delta)
	velocity.z = move_toward(velocity.z, target.z, 10.0 * delta)

	move_and_slide()

	# Actualización de comportamiento específico del enemigo.
	update_animation()


func _update_chase() -> void:
	if not player:
		chasing = false
		return

	var distancia := global_position.distance_to(player.global_position)

	if chasing:
		chasing = distancia <= lose_range
	else:
		chasing = distancia <= detection


func _on_hurt(hitbox: HitboxComponent) -> void:
	var away := global_position - hitbox.global_position
	away.y = 0.0

	if away.length() > 0.01:
		velocity += away.normalized() * recoil

	chasing = true

	# Permite que los enemigos con comportamientos especiales
	# reaccionen al recibir daño.
	on_hurt_effect(hitbox)


func on_hurt_effect(_hitbox: HitboxComponent) -> void:
	pass


func update_animation() -> void:
	pass


func _on_died() -> void:
	queue_free()
