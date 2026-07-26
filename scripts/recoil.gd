extends Node3D

@export var recoil_amount := Vector3(0.20, 0.015, 0.01)
@export var snap_amount: float = 15.0
@export var speed: float = 8.0

var current_rotation := Vector3.ZERO
var target_rotation := Vector3.ZERO


func _process(delta: float) -> void:
	target_rotation = target_rotation.lerp(
		Vector3.ZERO,
		clamp(speed * delta, 0.0, 1.0)
	)

	current_rotation = current_rotation.lerp(
		target_rotation,
		clamp(snap_amount * delta, 0.0, 1.0)
	)

	rotation = current_rotation

func add_recoil() -> void:
	target_rotation += Vector3(
		randf_range(recoil_amount.x * 0.8, recoil_amount.x),
		randf_range(-recoil_amount.y, recoil_amount.y),
		randf_range(-recoil_amount.z, recoil_amount.z)
	)
