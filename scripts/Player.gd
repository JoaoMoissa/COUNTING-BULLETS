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
const RELOAD_TIMER: float = 3.0
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
@onready var ammo_label: Label = $Head/Camera3D/CanvasLayer/AmmoLabel
@onready var reload_label: Label = $Head/Camera3D/CanvasLayer/ReloadLabel


func _update_ammo_ui():
	ammo_label.text = str(ammo_in_mag) + " / " + str(MAG_SIZE)

func _on_health_changed(new_health):
	healthbar.health = new_health

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_component.health_changed.connect(_on_health_changed)
	healthbar.init_health(health_component.health)
	reload_cooldown.timeout.connect(_on_reload_cooldown_timeout)
	reload_label.visible = false
	_update_ammo_ui()
	

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


#add the reload label
func _update_reload_ui():
	if reload_cooldown.is_stopped():
		reload_label.visible = false
	else:
		reload_label.visible = true
		reload_label.text = str(snapped(reload_cooldown.time_left, 0.1))

#shoot
func _handle_shoot() -> void:
	if is_reloading:
		return

	if not Input.is_action_just_pressed("shoot"):
		return

	if ammo_in_mag <= 0:
		return

	ammo_in_mag -= 1
	_update_ammo_ui()

	#aim in middle.
	var screen_center: Vector2 = get_viewport().get_visible_rect().size / 2.0
	var ray_origin: Vector3 = camera.project_ray_origin(screen_center)
	var ray_direction: Vector3 = camera.project_ray_normal(screen_center)
	var ray_end: Vector3 = ray_origin + ray_direction * 1000.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)

	query.exclude = [self]

	var space_state := get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)

	var target_position: Vector3 = ray_end
	if not result.is_empty():
		target_position = result["position"]

	var distance_from_barrel: float = gun_barrel.global_position.distance_to(target_position)
	
	if distance_from_barrel < 0.5:
		var camera_forward: Vector3 = -camera.global_transform.basis.z
		var camera_left: Vector3 = -camera.global_transform.basis.x

		var shoot_direction: Vector3 = (camera_forward + camera_left * 0.45).normalized()
		target_position = camera.global_position + shoot_direction * 1000.0
		
	#bullet
	var instance = bullet.instantiate()
	get_parent().add_child(instance)
	instance.global_position = gun_barrel.global_position
	instance.look_at(target_position, Vector3.UP)
	
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
	_update_ammo_ui()
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
	_update_reload_ui()
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
