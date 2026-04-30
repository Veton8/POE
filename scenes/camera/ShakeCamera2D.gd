class_name ShakeCamera2D
extends Camera2D

@export var max_offset: Vector2 = Vector2(8, 8)
@export var max_roll: float = 0.05
@export var decay: float = 1.5

var trauma: float = 0.0
var _noise: FastNoiseLite
var _t: float = 0.0

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 1.0
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	zoom = Vector2.ONE
	ignore_rotation = false
	limit_left = 0
	limit_top = 0
	limit_right = 480
	limit_bottom = 270
	Events.screen_shake.connect(add_trauma)

func add_trauma(amount: float, _duration: float = 0.0) -> void:
	trauma = clampf(trauma + amount * 0.1, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(trauma - decay * delta, 0.0)
		_t += delta * 60.0
		var amount := pow(trauma, 2)
		offset.x = max_offset.x * amount * _noise.get_noise_2d(0.0, _t)
		offset.y = max_offset.y * amount * _noise.get_noise_2d(100.0, _t)
		rotation = max_roll * amount * _noise.get_noise_2d(200.0, _t)
	else:
		offset = Vector2.ZERO
		rotation = 0.0
