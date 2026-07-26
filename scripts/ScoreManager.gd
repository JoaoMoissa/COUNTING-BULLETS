extends Node
signal score_changed(new_score)

var score: int = 0
var kills: int = 0

func add_kill(points: int) -> void:
	kills += 1
	score += points
	score_changed.emit(score)

func reset() -> void:
	score = 0
	kills = 0
	score_changed.emit(score)
