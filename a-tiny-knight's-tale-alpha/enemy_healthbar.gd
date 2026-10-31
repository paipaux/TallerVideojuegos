extends ProgressBar
@onready var health_component: HealthComponent = $"../../HealthComponent"
func _ready() -> void:
	print(health_component)
	if health_component:
		value = health_component.health
		health_component.health_changed.connect(_on_health_changed)




func _on_health_changed(hvalue: float) -> void:
	max_value = health_component.max_health
	value = hvalue
	
