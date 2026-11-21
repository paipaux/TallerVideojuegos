class_name HeartUI
extends TextureRect

@export var full: Texture2D
@export var half: Texture2D
@export var empty: Texture2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func update(health_heart: float, last_h: bool) -> void:
	if health_heart >= 1.0:
		texture = full
	elif health_heart >= 0.5:
		texture = half
	else:
		texture = empty

	if last_h and health_heart > 0.0:
		if not animation_player.is_playing():
			animation_player.play("palpitar")
	else: 
		animation_player.stop()
		scale = Vector2.ONE
	
