extends Node3D

@export var bounce_force: float = 7
@onready var bounce_area: Area3D = $BounceArea

func _ready() -> void:
	bounce_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("jugador"):
		return

	if not body is CharacterBody3D:
		return

	body.velocity.y = bounce_force
