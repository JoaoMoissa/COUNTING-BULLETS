extends Node
class_name Attack

var damage: float
var attacker: Node = null
var is_headshot: bool = false

func _init(new_damage: float, new_attacker: Node3D, headshot: bool = false) -> void:
	self.damage = new_damage
	self.attacker = new_attacker
	self.is_headshot = headshot
