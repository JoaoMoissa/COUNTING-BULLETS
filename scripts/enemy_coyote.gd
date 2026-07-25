extends CharacterBody3D

const bullet = preload("res://scenes/enemy_bullet.tscn")

@export var ShootDistance: float = 8.0
@export var ShootDelay: float = 1.5
@export var Points: int = 150
@export var HeadshotBonus: float = 1.5

@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var gun_barrel: Node3D = $VisualRoot/GunBarrel

@export var MoveSpeed: float = 4.0
@export var AttackReach: float = 1.5
@export var AttackDamage: float = 10.0
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var visual_root: Node3D = $VisualRoot



var player: CharacterBody3D = null
var preparing_to_shoot: bool = false

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
		

#enemy shoot
func try_shoot() -> void:
	if preparing_to_shoot:
		return

	if not shoot_cooldown.is_stopped():
		return

	preparing_to_shoot = true

	await get_tree().create_timer(ShootDelay).timeout

	preparing_to_shoot = false

	if global_position.distance_to(player.global_position) <= ShootDistance:
		shoot()
		shoot_cooldown.start()

func shoot() -> void:
	var instance = bullet.instantiate()
	get_parent().add_child(instance)
	instance.global_position = gun_barrel.global_position
	instance.look_at(player.global_position, Vector3.UP)


#movement of the enemy
func _process(_delta: float) -> void:
	navigation_agent.set_target_position(player.global_position)
	var target := player.global_position
	target.y = visual_root.global_position.y
	visual_root.look_at(target, Vector3.UP)
		
func _physics_process(_delta: float) -> void:
	
	process_move()
	var distance_to_player: float = global_position.distance_to(player.global_position)

	if distance_to_player <= ShootDistance:
		try_shoot()
	

func process_move() -> void:
	var distance_to_player: float = global_position.distance_to(player.global_position)

	if distance_to_player <= ShootDistance:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_position) * MoveSpeed

	move_and_slide()

func on_death(attack: Attack = null) -> void:
	var points: int = Points
	if attack != null and attack.is_headshot:
		points = int(points * HeadshotBonus)
	ScoreManager.add_kill(points)
	queue_free()
