extends Node3D

const SPEED = 70.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var ray: RayCast3D = $RayCast3D


func _ready() -> void:
	pass


func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
