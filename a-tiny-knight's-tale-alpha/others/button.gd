extends StaticBody3D

signal pressed
signal released

@onready var door: AnimatableBody3D = $"../Door"

var sword: Node3D = null

# espada clavada en el boton
func on_sword_pressed(swooord: Node3D) -> void:
	sword = swooord
	# al sacar la espada
	sword.tree_exiting.connect(on_sword_released)
	pressed.emit()
	
	if door:
		door.open()

func on_sword_released() -> void:
	sword = null
	released.emit()
	
	if door:
		door.close()
