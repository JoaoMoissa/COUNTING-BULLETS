class_name Reward
extends RefCounted

# Direct buffs granted on mission completion.
# Kept data-driven so a currency/shop type can be added later without
# touching the mission logic.
enum Type { FULL_HEAL, MAX_HEALTH, MAG_SIZE, DAMAGE }

var type: Type
var amount: float = 0.0
var text: String

func apply(player) -> void:
	match type:
		Type.FULL_HEAL:
			player.health_component.health = player.health_component.MaxHealth
			player.health_component.health_changed.emit(player.health_component.health)
			
		Type.MAX_HEALTH:
			player.health_component.MaxHealth += amount
			player.health_component.health = \
				player.health_component.MaxHealth

			player.healthbar.update_max_health(player.health_component.MaxHealth)

			player.health_component.health_changed.emit(player.health_component.health)
			
		Type.MAG_SIZE:
			player.mag_size += int(amount)
			player.ammo_in_mag = player.mag_size
			player._update_ammo_ui()
		Type.DAMAGE:
			player.bullet_damage_bonus += amount
