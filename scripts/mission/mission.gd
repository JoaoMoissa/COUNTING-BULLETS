class_name Mission
extends RefCounted

enum Type { KILLS, HEADSHOTS, SURVIVE_WAVE }

var type: Type
var description: String
var target: int
var progress: int = 0
var reward_text: String
var reward: Reward
var start_wave: int = 0  # wave index when a SURVIVE_WAVE mission was accepted

func is_complete() -> bool:
	return progress >= target
