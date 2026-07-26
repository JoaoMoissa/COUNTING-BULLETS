extends CharacterBody3D

var is_dead: bool = false
var can_take_damage: bool = true
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

#weapon animation variable
var last_muzzle_flash_frame: int = -1
var weapon_pivot_start_position: Vector2
var weapon_bob_time := 0.0
var reload_tween: Tween

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
var mag_size: int = 6  # mag capacity (buffable by mission rewards)
const RELOAD_TIMER: float = 1.5
var ammo_in_mag = mag_size
var reserve_ammo = 0
var is_reloading = false
var can_reload = false

# Combat modifiers (buffable by mission rewards)
var bullet_damage_bonus: float = 0.0

@onready var head = $Head
@onready var camera = $Head/Recoil/Camera3D
@onready var health_component: Node = $HealthComponent
@onready var healthbar = $Healthbar
@onready var gun_barrel = $Head/Recoil/Camera3D/Revolver/RayCast3D
@onready var reload_cooldown = $ReloadCooldown
@onready var ammo_label: Label = $Head/Recoil/Camera3D/CanvasLayer/AmmoLabel
@onready var reload_label: Label = $Head/Recoil/Camera3D/CanvasLayer/ReloadLabel
@onready var score_label: Label = $Head/Recoil/Camera3D/CanvasLayer/ScoreLabel #ScoreLabel to show score
@onready var round_label: Label = $Head/Recoil/Camera3D/CanvasLayer/RoundLabel
@onready var mission_label: Label = $Head/Recoil/Camera3D/CanvasLayer/MissionLabel


@onready var recoil = $Head/Recoil #recoil
@onready var death_screen: Control = $DeathCanvas/DeathScreen
#weapon animation
@onready var gun_sprite: AnimatedSprite2D = $Head/Recoil/Camera3D/CanvasLayer/WeaponPivot/Weapon
@onready var muzzle_flash: AnimatedSprite2D = $Head/Recoil/Camera3D/CanvasLayer/WeaponPivot/MuzzleFlash
@onready var weapon_pivot: Node2D = $Head/Recoil/Camera3D/CanvasLayer/WeaponPivot
@onready var weapon_animation_player: AnimationPlayer = \
	$Head/Recoil/Camera3D/CanvasLayer/AnimationPlayer
@onready var reload_visual: Node2D = \
	$Head/Recoil/Camera3D/CanvasLayer/WeaponPivot/ReloadVisual
@onready var reload_cylinder: Sprite2D = \
	$Head/Recoil/Camera3D/CanvasLayer/WeaponPivot/ReloadVisual/Cylinder

func _update_ammo_ui():
	ammo_label.text = str(ammo_in_mag)

func _on_score_changed(new_score):
	score_label.text = "Score: %d" % new_score

func _on_health_changed(new_health):
	healthbar.health = new_health

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_component.health_changed.connect(_on_health_changed)
	healthbar.init_health(health_component.health)
	weapon_pivot_start_position = weapon_pivot.position
	reload_label.visible = false
	reload_visual.hide()
	muzzle_flash.hide()
	_update_ammo_ui()
	
	# Update score
	ScoreManager.reset() 
	ScoreManager.score_changed.connect(_on_score_changed)
	_on_score_changed(ScoreManager.score)
	
	# Reset Mission
	MissionManager.reset()
	
	# Wave HUD
	var wm = get_tree().get_first_node_in_group("WaveManager")
	if wm:
		wm.wave_changed.connect(_on_wave_changed)
		_on_wave_changed(wm.current_wave)

	# Mission HUD
	MissionManager.mission_accepted.connect(_on_mission_updated)
	MissionManager.mission_progress.connect(_on_mission_updated)
	MissionManager.mission_completed.connect(_on_mission_completed)
	_refresh_mission_ui()
	
	gun_sprite.play("idle")

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * Settings.mouse_sensitivity)
		camera.rotate_x(-event.relative.y * Settings.mouse_sensitivity)
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
	if is_reloading or is_dead:
		return

	if not Input.is_action_just_pressed("shoot"):
		return

	if ammo_in_mag <= 0:
		var tutorial_controller = get_tree().get_first_node_in_group("TutorialController")

		if (tutorial_controller and tutorial_controller.tutorial_active):
			return

		on_death()
		return

	ammo_in_mag -= 1
	
	if ammo_in_mag == 0:
		var tutorial_controller = get_tree().get_first_node_in_group("TutorialController")

		if tutorial_controller:
			tutorial_controller.notify_magazine_empty()
	
	_update_ammo_ui()
	gun_sprite.play("shoot")
	_show_random_muzzle_flash()
	
	weapon_animation_player.stop()
	weapon_animation_player.play("weapon_recoil")

	recoil.add_recoil()
	


	#aim in middle.
	var screen_center: Vector2 = get_viewport().get_visible_rect().size / 2.0 
	var ray_origin: Vector3 = camera.project_ray_origin(screen_center)
	var ray_direction: Vector3 = camera.project_ray_normal(screen_center)
	var ray_end: Vector3 = ray_origin + ray_direction * 1000.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)


	query.collide_with_areas = true
	query.collide_with_bodies = true

	query.exclude = [self.get_rid()]


	var space_state := get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)

	var target_position: Vector3 = ray_end
	if not result.is_empty():
		target_position = result["position"]

	var distance_from_barrel: float = gun_barrel.global_position.distance_to(target_position)
	
	if distance_from_barrel < 1.5:target_position = (gun_barrel.global_position+ ray_direction * 1000.0)
		
	#bullet
	var instance = bullet.instantiate()
	instance.damage += bullet_damage_bonus  # apply damage buff from rewards
	get_parent().add_child(instance)
	instance.global_position = gun_barrel.global_position
	instance.look_at(target_position, Vector3.UP)
	
	if ammo_in_mag == 0:
		can_reload = false
		reload_cooldown.start()

#revolver animations

func _finish_reload_animation() -> void:
	if reload_tween != null:
		reload_tween.kill()
		reload_tween = null

	reload_cylinder.rotation = 0.0
	reload_visual.hide()

	gun_sprite.show()
	gun_sprite.play("idle")

func _start_reload_animation() -> void:
	gun_sprite.hide()
	muzzle_flash.hide()
	reload_visual.show()

	if reload_tween != null:
		reload_tween.kill()
		reload_tween = null
	
	reload_cylinder.rotation = 0.0
	
	reload_tween = create_tween()
	reload_tween.set_loops()

	reload_tween.tween_interval(0.25)
	
	reload_tween.tween_property(reload_cylinder, "rotation", -TAU, 0.35)

# weapon bob
func _update_weapon_bob(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()

	if horizontal_speed > 0.1 and is_on_floor():
		var speed_ratio: float = inverse_lerp(WALK_SPEED, SPRINT_SPEED, horizontal_speed)

		speed_ratio = clamp(speed_ratio, 0.0, 1.0)

		var bob_frequency: float = lerp(5.0, 8.0, speed_ratio)
		var bob_horizontal_amount: float = lerp(3.0, 8.0, speed_ratio)
		var bob_vertical_amount: float = lerp(7.0, 10.0, speed_ratio)

		weapon_bob_time += delta * bob_frequency

		var bob_x: float = cos(weapon_bob_time) * bob_horizontal_amount
		var bob_y: float = absf(sin(weapon_bob_time)) * bob_vertical_amount

		var target_position: Vector2 = (
			weapon_pivot_start_position
			+ Vector2(bob_x, bob_y)
		)

		weapon_pivot.position = weapon_pivot.position.lerp(
			target_position,
			min(delta * 12.0, 1.0)
		)
	else:
		weapon_bob_time = 0.0

		weapon_pivot.position = weapon_pivot.position.lerp(
			weapon_pivot_start_position,
			min(delta * 8.0, 1.0)
		)


# weapon muzzle
func _show_random_muzzle_flash() -> void:
	var available_frames: Array[int] = [0, 1, 2, 3]

	var selected_frame: int = available_frames.pick_random()

	muzzle_flash.animation = "flash"
	muzzle_flash.frame = selected_frame
	muzzle_flash.show()

	await get_tree().create_timer(0.06).timeout

	muzzle_flash.hide()
	

# weapon shoot animation
func _on_weapon_animation_finished() -> void:
	if gun_sprite.animation == "shoot":
		gun_sprite.play("idle")
		
		
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
	_start_reload_animation()
	await get_tree().create_timer(RELOAD_TIMER).timeout
	_finish_reload_animation()
	ammo_in_mag = mag_size
	_update_ammo_ui()
	is_reloading = false
	can_reload = false

	var tutorial_controller = get_tree().get_first_node_in_group(
	"TutorialController"
)

	if tutorial_controller:
		tutorial_controller.notify_player_reloaded()
		
		
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
	
	# weapon bob
	_update_weapon_bob(delta)
	
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
	

func on_death(_attack: Attack = null) -> void:
	if is_dead:
		return
		
	is_dead = true
	death_screen.show_death_screen(ScoreManager.score)


func _on_reload_cooldown_timeout() -> void:
	can_reload = true

# Missions
func _on_wave_changed(wave):
	round_label.text = "%d" % wave

func _on_mission_updated(mission):
	mission_label.text = "MISSION: %s  (%d/%d)" % [mission.description, mission.progress, mission.target]

func _on_mission_completed(_mission):
	mission_label.text = "Mission Completed"
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		_refresh_mission_ui()

func _refresh_mission_ui():
	if MissionManager.has_active_mission():
		_on_mission_updated(MissionManager.active_mission)
	else:
		mission_label.text = "No Mission Active"
