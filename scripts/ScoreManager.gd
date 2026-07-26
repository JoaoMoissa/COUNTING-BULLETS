extends Node
signal score_changed(new_score)
signal enemy_killed(is_headshot: bool)

var score: int = 0
var kills: int = 0

func add_kill(points: int, is_headshot: bool = false) -> void:
	kills += 1
	score += points
	score_changed.emit(score)
	enemy_killed.emit(is_headshot)

func reset() -> void:
	score = 0
	kills = 0
	score_changed.emit(score)
