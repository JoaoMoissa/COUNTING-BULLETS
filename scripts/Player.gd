extends CharacterBody3D


var can_take_damage: bool = true
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

#bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

#bullets variables
const bullet = preload("res://scenes/bullet.tscn")

# Ammo variables
const MAG_SIZE = 6
const RELOAD_TIMER = 3
var ammo_in_mag = MAG_SIZE
var reserve_ammo = 0
var is_reloading = false
var can_reload = false

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var health_component: Node = $HealthComponent
@onready var healthbar = $Healthbar
@onready var gun_barrel = $Head/Camera3D/Revolver/RayCast3D
@onready var reload_cooldown = $ReloadCooldown


func _on_health_changed(new_health):
	healthbar.health = new_health

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_component.health_changed.connect(_on_health_changed)
	healthbar.init_health(health_component.health)
	reload_cooldown.timeout.connect(_on_reload_cooldown_timeout)
	

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


#shoot
func _handle_shoot():
	if is_reloading:
		return
	
	if Input.is_action_just_pressed("shoot") and ammo_in_mag > 0:
		ammo_in_mag -= 1
		var instance = bullet.instantiate()
		instance.position = gun_barrel.global_position
		instance.transform.basis = gun_barrel.global_transform.basis
		get_parent().add_child(instance)
		if ammo_in_mag == 0:
			can_reload = false
			reload_cooldown.start()

func _handle_reload():
	if Input.is_action_just_pressed("reload"):
		_reload()

func _reload():
	# player can't reload if mag isn't empty
	if is_reloading or ammo_in_mag > 0:
		return
	
	if not can_reload:
		reload_cooldown.start()
		return
	
	# Time is up
	is_reloading = true
	await get_tree().create_timer(RELOAD_TIMER).timeout
	ammo_in_mag = MAG_SIZE
	is_reloading = false
	can_reload = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Defines the input direction.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint") and input_dir.y < 0:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Gun
	_handle_shoot()
	_handle_reload()
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	

func on_death() -> void:
	get_tree().quit()


func _on_reload_cooldown_timeout() -> void:
	can_reload = true
