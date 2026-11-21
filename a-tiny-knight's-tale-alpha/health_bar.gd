class_name HeartsContainer
extends HBoxContainer

@export var health_heart: float = 20.0 

func setup(health_component: HealthComponent) -> void:
	health_heart = health_component.max_health / get_child_count()
	health_component.health_changed.connect(_health_change)
	
	_health_change(health_component.health)

func _health_change(current_health: float) -> void:
	var hearts_value := current_health / health_heart
	var danger: bool = (hearts_value > 0.0 and hearts_value <= 1.0)
	var hearts := get_children()

	for i in hearts.size():
		var h := hearts[i] as HeartUI
		
		if not h:
			continue
		
		var current_heart: float = clampf((hearts_value - i), 0.0, 1.0)
		var palpitar: bool = (i==0 and danger)
		
		h.update(current_heart, palpitar)
