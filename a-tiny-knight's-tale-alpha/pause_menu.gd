extends CanvasLayer

@onready var resume: Button = %Resume
@onready var retry: Button = %Retry
@onready var back: Button = %Back
@onready var quit: Button = %Quit

func _ready() -> void:
	hide()
	resume.pressed.connect(_on_resume_pressed)
	retry.pressed.connect(_on_retry_pressed)
	back.pressed.connect(_on_back_pressed)
	quit.pressed.connect(_on_quiiit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_set_paused(not get_tree().paused)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	# por qué no sale el mouseeeee -> habian dos menus de pausa xd
	print("[PauseMenu: %s] paused=%s | visible=%s | mouse_mode=%s" % [
		name,
		get_tree().paused,
		visible,
		Input.mouse_mode
	])

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()
	
func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_back_pressed() -> void:
	# aun no hay menuu
	pass
	
func _on_quiiit_pressed() -> void:
	# para testear y arreglar más facil, despues habria que sacar este creo jsdhjs
	get_tree().quit()
