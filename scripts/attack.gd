extends Node
class_name Attack

var damage: float
var attacker: Node = null
var is_headshot: bool = false

func _init(damage: float, attacker: Node3D, is_headshot: bool = false) -> void:
	self.damage = damage
	self.attacker = attacker
	self.is_headshot = is_headshot
