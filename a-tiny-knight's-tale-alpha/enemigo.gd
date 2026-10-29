extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent

@export var speed: float = 3.0 # Velocidad de movimiento del enemigo
var player: Node3D = null

func _ready() -> void:
	health_component.died.connect(_on_died)
	
	# se busca al jugador
	player = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta: float) -> void:
	if player:
		# se calcula la dirección hacia el jugador
		var direction = (player.global_position - global_position).normalized()
		
		# hacemps que el enemigo mire hacia el jugador
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		# se aplica velocidad en el plano horizontal (X y Z)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# añadimos gravedad
		if not is_on_floor():
			velocity.y -= 9.8 * delta
	else:
		# si por alguna razón no encuentra al jugador, se detiene
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# se mueve el personaje usando las físicas de Godot
	move_and_slide()

func _on_died() -> void:
	queue_free()
