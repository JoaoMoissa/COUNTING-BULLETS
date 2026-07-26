extends Node

signal mission_progress(mission)
signal mission_completed(mission)
signal mission_accepted(mission)

var active_mission: Mission = null
var current_wave: int = 0

func reset() -> void:
	active_mission = null
	# current_wave is kept in sync by WaveManager; do not zero it here

func _ready() -> void:
	ScoreManager.enemy_killed.connect(_on_enemy_killed)
	# WaveManager pushes the wave via set_current_wave(); no lookup here
	# because this autoload boots before any level scene exists

func has_active_mission() -> bool:
	return active_mission != null

func offer_missions() -> Array:
	return [_random_mission(), _random_mission(), _random_mission()]

func accept(m: Mission) -> void:
	active_mission = m
	if m.type == Mission.Type.SURVIVE_WAVE:
		m.start_wave = current_wave  # anchor survival at the current wave
	mission_accepted.emit(m)
	print("[MISSION] Accepted: ", m.description)

func _random_mission() -> Mission:
	var m := Mission.new()
	match randi() % 3:
		0:
			m.type = Mission.Type.KILLS
			m.target = randi_range(5, 12)
			m.description = "Kill %d enemies" % m.target
		1:
			m.type = Mission.Type.HEADSHOTS
			m.target = randi_range(3, 8)
			m.description = "Hit %d headshots" % m.target
		2:
			m.type = Mission.Type.SURVIVE_WAVE
			m.target = randi_range(2, 4)  # number of waves to survive
			m.description = "Survive %d waves" % m.target
	m.reward = _random_reward()
	m.reward_text = m.reward.text
	return m

func _random_reward() -> Reward:
	var r := Reward.new()
	match randi() % 4:
		0:
			r.type = Reward.Type.FULL_HEAL
			r.text = "Full heal"
		1:
			r.type = Reward.Type.MAX_HEALTH
			r.amount = 25
			r.text = "+25 max health"
		2:
			r.type = Reward.Type.MAG_SIZE
			r.amount = 2
			r.text = "+2 mag capacity"
		3:
			r.type = Reward.Type.DAMAGE
			r.amount = 10
			r.text = "+10 damage"
	return r

func _on_enemy_killed(is_headshot: bool) -> void:
	if active_mission == null:
		return
	if active_mission.type == Mission.Type.KILLS:
		active_mission.progress += 1
	elif active_mission.type == Mission.Type.HEADSHOTS and is_headshot:
		active_mission.progress += 1
	else:
		return
	_report_progress()

func set_current_wave(wave: int) -> void:
	current_wave = wave
	if active_mission and active_mission.type == Mission.Type.SURVIVE_WAVE:
		active_mission.progress = current_wave - active_mission.start_wave
		_report_progress()

func _report_progress() -> void:
	mission_progress.emit(active_mission)
	print("[MISSION] %d/%d" % [active_mission.progress, active_mission.target])
	if active_mission.is_complete():
		_complete()

func _complete() -> void:
	print("[MISSION] COMPLETED: %s -> %s" % [active_mission.description, active_mission.reward_text])
	_grant_reward()
	mission_completed.emit(active_mission)
	active_mission = null

func _grant_reward() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and active_mission and active_mission.reward:
		active_mission.reward.apply(player)
