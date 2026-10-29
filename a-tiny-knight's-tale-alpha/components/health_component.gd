class_name HealthComponent
extends Node

signal health_changed(value: float)
signal died

# ajustar para los distintos tipo de enemigos: gnomo y shrek xd
@export var health: float = 100:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)
		if health == 0:
			died.emit()

@export var max_health: float = 100
