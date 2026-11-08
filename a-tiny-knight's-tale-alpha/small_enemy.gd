
extends "res://enemies/enemigo.gd"

@onready var animation_tree: AnimationTree = $Model/SmallEnemy/AnimationTree

var animation_playback: AnimationNodeStateMachinePlayback


func _ready() -> void:
	super._ready()

	animation_tree.active = true
	animation_playback = animation_tree["parameters/playback"]


func update_animation() -> void:
	if animation_playback == null:
		return

	var current_animation = animation_playback.get_current_node()

	# No interrumpir Damage ni Attack.
	if current_animation == "Damage" or current_animation == "Attack":
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	var next_animation: String

	if horizontal_speed > 0.1:
		next_animation = "Walk"
	else:
		next_animation = "Idle"

	if current_animation != next_animation:
		animation_playback.travel(next_animation)


func on_hurt_effect(_hitbox: HitboxComponent) -> void:
	if animation_playback != null:
		animation_playback.start("Damage")


func play_attack() -> void:
	if animation_playback != null:
		animation_playback.travel("Attack")
