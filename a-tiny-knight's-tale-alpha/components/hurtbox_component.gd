class_name HurtboxComponent
extends Area3D

signal hurt(hitbox: HitboxComponent)

@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	print("hubo golpe con: ", area.name)

	var hitbox_component: HitboxComponent = area as HitboxComponent
	print("hitbox_component: ", hitbox_component)
	print("health_component: ", health_component)

	if hitbox_component and health_component:
		health_component.health -= hitbox_component.damage
		print(health_component.health)
		hitbox_component.damage_dealt.emit()
