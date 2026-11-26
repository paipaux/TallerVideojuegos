class_name HitboxComponent
extends Area3D

signal damage_dealt

# ajustar desde el inpector por tipo de enemigo: gnomo o shrek cocinero
@export var damage: float = 10.0
@export var knockback_force: float = 3.0
@export var knockback_vertical: float = 3.0
