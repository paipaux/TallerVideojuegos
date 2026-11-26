extends AnimatableBody3D
#Variable que controla la velocidad con que rota la plataforma
@export var rotation_speed: float = 1.0

#Funcion para que el tronco rote sobre si
func _physics_process(delta: float) -> void:
	rotate_z(rotation_speed * delta)
