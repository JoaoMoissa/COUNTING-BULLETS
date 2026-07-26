extends CharacterBody3D

@export var Points: int = 100
@export var HeadshotBonus: float = 1.5
@export var MoveSpeed: float = 4.0
@export var AttackReach: float = 1.5
@export var AttackDamage: float = 10.0
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var visual_root: Node3D = $VisualRoot

var player: CharacterBody3D = null

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
	

#movement of the enemy
func _process(_delta: float) -> void:
	navigation_agent.set_target_position(player.global_position)
	var target := player.global_position
	target.y = visual_root.global_position.y
	visual_root.look_at(target, Vector3.UP)
	

func _physics_process(delta: float) -> void:
	# gravidade sempre
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	
	if global_position.distance_to(player.global_position) < AttackReach:
		if attack_cooldown.is_stopped():
			var attack: Attack = Attack.new(AttackDamage, self)
			player.health_component.damage(attack)
			attack_cooldown.start()
	
	_update_move_velocity()
	move_and_slide()          # um único move_and_slide, no fim

func _update_move_velocity() -> void:
	# parado ao atacar ou ao terminar o caminho: zera só o horizontal
	if not attack_cooldown.is_stopped() or navigation_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return
	
	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var dir: Vector3 = global_position.direction_to(next_position)
	velocity.x = dir.x * MoveSpeed
	velocity.z = dir.z * MoveSpeed

func on_death(attack: Attack = null) -> void:
	var points: int = Points
	if attack != null and attack.is_headshot:
		points = int(points * HeadshotBonus)
	ScoreManager.add_kill(points)
	queue_free()
