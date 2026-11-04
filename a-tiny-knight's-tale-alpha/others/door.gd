extends AnimatableBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func open() -> void:
	animation_player.play("open")

func close() -> void:
	animation_player.play_backwards("open")
