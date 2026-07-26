extends ProgressBar

@export var base_max_health: float = 100.0
@export var base_width: float = 300.0
@export var width_per_health: float = 2.0

#nodes
@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

#animation
var damage_tween: Tween

#health
var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health

	#faz a barra sumir
	#if health <= 0:
		#queue_free()
		
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health
		
func init_health(initial_health: float) -> void:
	base_max_health = initial_health
	base_width = size.x

	max_value = initial_health
	value = initial_health

	damage_bar.max_value = initial_health
	damage_bar.value = initial_health

func _on_timer_timeout() -> void:
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	damage_tween.set_trans(Tween.TRANS_SINE)
	damage_tween.set_ease(Tween.EASE_OUT)
	damage_tween.tween_property(damage_bar, "value", health, 0.25)

func update_max_health(new_max_health: float) -> void:
	max_value = new_max_health
	damage_bar.max_value = new_max_health

	var extra_health: float = new_max_health - base_max_health
	var new_width: float = base_width + extra_health * width_per_health

	custom_minimum_size.x = new_width
	size.x = new_width

	damage_bar.custom_minimum_size.x = new_width
	damage_bar.size.x = new_width
