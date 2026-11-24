extends Camera3D

# Velocidad de giro en grados por segundo
@export var velocidad_giro: float = 90.0
# Qué tan rápido la cámara alcanza el objetivo (más alto = más brusco, más bajo = más suave)
@export var suavizado: float = 8.0
# Límites del giro vertical (arriba/abajo) en grados
@export var inclinacion_min: float = -80.0
@export var inclinacion_max: float = 80.0

# Rotación objetivo (hacia donde queremos llegar)
var objetivo_yaw: float
var objetivo_pitch: float


func _ready() -> void:
	# Partimos desde la rotación que tenga la cámara en el editor
	objetivo_yaw = rotation_degrees.y
	objetivo_pitch = rotation_degrees.x


func _process(delta: float) -> void:
	var giro_h := Input.get_axis("ui_right", "ui_left")
	var giro_v := Input.get_axis("ui_down", "ui_up")

	# Las flechas mueven el objetivo
	objetivo_yaw += giro_h * velocidad_giro * delta
	objetivo_pitch = clamp(
		objetivo_pitch + giro_v * velocidad_giro * delta,
		inclinacion_min,
		inclinacion_max
	)

	# La cámara se acerca al objetivo de forma gradual
	# (esta fórmula da el mismo resultado sin importar los FPS)
	var t := 1.0 - exp(-suavizado * delta)
	rotation_degrees.y = lerp(rotation_degrees.y, objetivo_yaw, t)
	rotation_degrees.x = lerp(rotation_degrees.x, objetivo_pitch, t)
