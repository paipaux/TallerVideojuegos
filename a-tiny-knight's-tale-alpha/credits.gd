extends Control

@onready var baack: Button = $Baack

func _ready() -> void:
	baack.pressed.connect(_on_baack_pressed)

func _on_baack_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")
