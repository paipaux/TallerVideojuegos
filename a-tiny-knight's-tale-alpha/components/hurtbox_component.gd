class_name HurtboxComponent
extends Area3D

signal hurt(hitbox: HitboxComponent)

@export var health_component: HealthComponent
@export var invulnerability_time: float = 0.0

var invulnerable: bool = false

func _ready() -> void:
	area_entered.connect(_try_hit)

func _physics_process(delta: float) -> void:
	if invulnerability_time > 0.0 and not invulnerable:
		for area in get_overlapping_areas():
			_try_hit(area)

func _try_hit(area: Area3D) -> void:
	print("hubo golpe con: ", area.name)

	if invulnerable:
		return

	var hitbox_component: HitboxComponent = area as HitboxComponent
	print("hitbox_component: ", hitbox_component)
	print("health_component: ", health_component)

	if not hitbox_component or not health_component:
		return

	health_component.health -= hitbox_component.damage
	print(health_component.health)
	hitbox_component.damage_dealt.emit()
	hurt.emit(hitbox_component)

	if invulnerability_time > 0.0:
		invulnerable = true
	
		await get_tree().create_timer(invulnerability_time).timeout
		invulnerable = false
