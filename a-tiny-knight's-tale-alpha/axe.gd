extends Node3D

@export var rotation_angle: float = 45.0
@export var rotation_speed: float = 2.5

@onready var pivot: AnimatableBody3D = $Pivot

var initial_rotation: float

func _ready() -> void:
	initial_rotation = pivot.rotation.z

func _physics_process(_delta: float) -> void:
	var angle = sin(Time.get_ticks_msec() / 1000.0 * rotation_speed)
	pivot.rotation.z = initial_rotation + deg_to_rad(rotation_angle) * angle
