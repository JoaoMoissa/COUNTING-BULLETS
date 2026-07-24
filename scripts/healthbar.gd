extends ProgressBar

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
		
func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _on_timer_timeout() -> void:
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	damage_tween.set_trans(Tween.TRANS_SINE)
	damage_tween.set_ease(Tween.EASE_OUT)
	damage_tween.tween_property(damage_bar, "value", health, 0.25)
