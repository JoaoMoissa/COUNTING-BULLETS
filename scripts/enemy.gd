extends CharacterBody3D

@export var MoveSpeed: float = 4.0
@export var AttackReach: float = 1.5
@export var AttackDamage: float = 10.0
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_cooldown: Timer = $AttackCooldown

var player: CharacterBody3D = null

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
		
	
#movement of the enemy
func _process(_delta: float) -> void:
	navigation_agent.set_target_position(player.global_position)
	
		
func _physics_process(_delta: float) -> void:
	
	if global_position.distance_to(player.global_position) < AttackReach:
		if attack_cooldown.is_stopped():
			var attack: Attack = Attack.new(AttackDamage, self)
			player.health_component.damage(attack)
			attack_cooldown.start()
		
	process_move()
	

func process_move() -> void:
	if not attack_cooldown.is_stopped():
		velocity = Vector3.ZERO
		return
		
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	
	var next_position: Vector3 = navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_position) * MoveSpeed
	
	move_and_slide()

func on_death() -> void:
	queue_free()
