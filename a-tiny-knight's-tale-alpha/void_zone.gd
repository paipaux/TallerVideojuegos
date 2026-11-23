extends Area3D

@export var tick_interval: float = 0.3
@onready var hitbox: HitboxComponent = $HitboxComponent

var _timer: float = 0.0
var _target_hurtboxes: Array[HurtboxComponent] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
func _physics_process(delta: float) -> void:
	if _target_hurtboxes.is_empty():
		_timer = 0.0
		return

	_timer += delta
	if _timer >= tick_interval:
		_timer -= tick_interval
		_apply_tick_damage()

func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox and hurtbox not in _target_hurtboxes:
		_target_hurtboxes.append(hurtbox)
		# Golpe inmediato al entrar y luego cada 0.3s mientras siga cayendo
		_hit_hurtbox(hurtbox)
		_timer = 0.0

func _on_area_exited(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox:
		_target_hurtboxes.erase(hurtbox)

func _apply_tick_damage() -> void:
	for i in range(_target_hurtboxes.size() - 1, -1, -1):
		var hurtbox := _target_hurtboxes[i]
		if not is_instance_valid(hurtbox):
			_target_hurtboxes.remove_at(i)
			continue
		_hit_hurtbox(hurtbox)

func _hit_hurtbox(hurtbox: HurtboxComponent) -> void:
	if not hitbox or not hurtbox.health_component:
		return

	# Si la vida va a llegar a 0 con este golpe, lo sacamos de la lista ANTES de restar vida
	var will_die := (hurtbox.health_component.health - hitbox.damage) <= 0.0
	if will_die:
		_target_hurtboxes.erase(hurtbox)
		_timer = 0.0

	hurtbox.health_component.health -= hitbox.damage
	hitbox.damage_dealt.emit()
	hurtbox.hurt.emit(hitbox)
