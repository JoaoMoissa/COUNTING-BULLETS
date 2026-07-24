extends Node
class_name Attack

var damage: float
var attacker: Node = null

func _init(damage: float, attacker: Node3D) -> void:
	self.damage = damage
	self.attacker = attacker	
