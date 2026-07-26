extends Node

@export var enemy_scenes: Array[PackedScene] = []   # enemies scenes
@onready var spawn_points: Array[Node] = \
	get_parent().get_node("SpawnPoints").get_children()     # All Markers
@export var enemies_container: Node3D               # Enemies Node

@export var base_count: int = 5          # First Wave
@export var count_growth: int = 2        # +N enemies per wave
@export var max_concurrent: int = 6      # Max enemies on screen
@export var spawn_interval: float = 1.0  # (trickle)
@export var wave_delay: float = 3.0      # time between waves

var current_wave: int = 0
var to_spawn: int = 0     # How many left?
var alive: int = 0        # How many alive?

@onready var spawn_timer: Timer = $SpawnTimer

signal wave_changed(wave)

func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _start_next_wave() -> void:
	current_wave += 1
	to_spawn = base_count + (current_wave - 1) * count_growth
	wave_changed.emit(current_wave)
	MissionManager.set_current_wave(current_wave)  # keep mission logic in sync
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if to_spawn > 0 and alive < max_concurrent:
		_spawn_one()

func _spawn_one() -> void:
	var enemy = enemy_scenes.pick_random().instantiate()
	enemies_container.add_child(enemy)
	enemy.global_position = spawn_points.pick_random().global_position
	enemy.tree_exited.connect(_on_enemy_died)
	to_spawn -= 1
	alive += 1
	if to_spawn == 0:
		spawn_timer.stop()

func _on_enemy_died() -> void:
	if not is_inside_tree():
		return
	alive -= 1
	if to_spawn == 0 and alive == 0:
		_end_wave()

func _end_wave() -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(wave_delay).timeout
	if not is_inside_tree():
		return
	_start_next_wave()

func start_tutorial_enemy() -> void:
	current_wave = 1
	to_spawn = 1
	alive = 0

	wave_changed.emit(current_wave)
	MissionManager.set_current_wave(current_wave)

	_spawn_one()

func start_tutorial_combat() -> void:
	to_spawn = 5
	spawn_timer.start()

func start_wave_two() -> void:
	current_wave = 1
	_start_next_wave()
