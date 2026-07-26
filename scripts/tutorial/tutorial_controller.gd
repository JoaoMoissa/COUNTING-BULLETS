extends Node

enum TutorialState {
	STARTING,
	WAITING_FIRST_KILL,
	WAITING_EMPTY_MAGAZINE,
	WAITING_RELOAD,
	FINISHED
}

@onready var cat_dialogue: Control = $"../Player/CatCanvas/CatDialogue"
@onready var player = $"../Player"
@onready var wave_manager = $"../WaveManager"
@onready var ammo_label: Label = $"../Player/Head/Recoil/Camera3D/CanvasLayer/AmmoLabel"
@onready var reload_label: Label = $"../Player/Head/Recoil/Camera3D/CanvasLayer/ReloadLabel"

var state: TutorialState = TutorialState.STARTING
var tutorial_active: bool = true


func _ready() -> void:
	add_to_group("TutorialController")
	
	await get_tree().process_frame
	_start_tutorial()


func _spawn_tutorial_enemy() -> void:
	print("Spawnar primeiro inimigo do tutorial")


func _start_tutorial() -> void:
	state = TutorialState.STARTING
	ammo_label.show()
	reload_label.show()
	cat_dialogue.start_dialogue([
		"Looks like you're alive.",
		"Hey! You can thank me later.",
		"Look out! Enemies are coming.",
		"I want to see what you're capable of."
	])

	await cat_dialogue.dialogue_finished

	state = TutorialState.WAITING_FIRST_KILL

	_spawn_tutorial_enemy()


func _start_tutorial_combat() -> void:
	print("Spawnar inimigos até o pente esvaziar")


func notify_enemy_killed() -> void:
	if not tutorial_active:
		return

	if state != TutorialState.WAITING_FIRST_KILL:
		return

	state = TutorialState.WAITING_EMPTY_MAGAZINE

	cat_dialogue.start_dialogue([
		"Heh... only that?",
		"Okay, let's increase the level.",
		"I won't let you reload the weapon until it's empty."
	])

	await cat_dialogue.dialogue_finished

	_start_tutorial_combat()


func notify_magazine_empty() -> void:
	if not tutorial_active:
		return

	if state != TutorialState.WAITING_EMPTY_MAGAZINE:
		return

	state = TutorialState.WAITING_RELOAD

	cat_dialogue.start_dialogue([
		"Careful!",
		"If you pull the trigger without bullets...",
		"I'm going to kill you.",
		"Press R to reload."
	])

	await cat_dialogue.dialogue_finished


func notify_player_reloaded() -> void:
	if not tutorial_active:
		return

	if state != TutorialState.WAITING_RELOAD:
		return

	finish_tutorial()


func _start_wave_two() -> void:
	print("Começar onda 2")


func finish_tutorial() -> void:
	state = TutorialState.FINISHED
	tutorial_active = false
	player.ammo_label.visible = false
	player.reload_label.visible = false
	
	print("Tutorial concluído")
	cat_dialogue.start_dialogue([
		"Now count for yourself!"
	])
	_start_wave_two()
