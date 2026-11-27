extends Control

@onready var iniciar: Button = %Iniciar
@onready var creditos: Button = %Creditos
@onready var salir: Button = %Salir

func _ready() -> void:
	iniciar.pressed.connect(_on_start_pressed)
	creditos.pressed.connect(_on_credits_pressed)
	salir.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	pass

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
