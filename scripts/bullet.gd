extends Area3D

var has_hit: bool = false

const SPEED = 30.0

@export var lifetime: float = 3.0
@export var damage: float = 25.0
@export var headshot_multiplier: float = 2.0

#scan for obstacles
func _physics_process(delta: float) -> void:
	var movement: Vector3 = (global_transform.basis * Vector3(0, 0, -SPEED) * delta)
	var next_position: Vector3 = global_position + movement

	var query := PhysicsRayQueryParameters3D.create(global_position, next_position)

	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		var collider = result["collider"]

		if collider.is_in_group("World"):
			has_hit = true
			queue_free()
			return

	global_position = next_position

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()

# When enter the area
func _on_area_entered(area: Area3D) -> void:
	if has_hit:
		return
	
	if not area.is_in_group("Hitbox"):
		return
		
	has_hit = true
	
	var enemy = _find_enemy(area)
	
	if enemy == null:
		queue_free()
		return
		
	var health_component = enemy.get_node("HealthComponent")
	
	var final_damage: float = damage
	var is_headshot: bool = area.is_in_group("Head")
	
	if is_headshot:
		final_damage *= headshot_multiplier
		print("HEADSHOT!")
	
	var attack = Attack.new(final_damage, self, is_headshot)
	health_component.damage(attack)
	
	queue_free()

func _find_enemy(hitbox: Node) -> Node:
	var current_node = hitbox.get_parent()
	
	while current_node != null:
		if current_node.has_node("HealthComponent"):
			return current_node
			
		current_node = current_node.get_parent()
		
	return null
	
func _on_body_entered(body: Node3D) -> void:

	if has_hit:
		return

	if not body.is_in_group("World"):
		return

	has_hit = true

	queue_free()

func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	
	
