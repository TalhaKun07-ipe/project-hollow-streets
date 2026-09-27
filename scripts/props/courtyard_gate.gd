extends Node3D

# Interactive Apartment Courtyard Iron Gate
# Can be unlocked using the Rusted Brass Key.

@export var is_unlocked: bool = false

@onready var area: Area3D = $Area3D
@onready var door_pivot: Node3D = $DoorPivot
@onready var blocker_collision: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var sfx_player: AudioStreamPlayer3D = $SFXPlayer3D

const SOUND_UNLOCK: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const SOUND_OPEN: AudioStream = preload("res://assets/audio/footstep_land.wav")

var player_in_range: bool = false
var hud_node: Node = null

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_unlocked:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_try_unlock()

func _on_body_entered(body: Node3D) -> void:
	if is_unlocked or not (body is CharacterBody3D):
		return
	player_in_range = true
	hud_node = get_tree().root.find_child("ObjectiveHUD", true, false)
	_update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)

func _update_prompt() -> void:
	if not hud_node or not hud_node.has_method("show_interact_prompt"):
		return
	if GameManager.has_item("brass_key"):
		hud_node.show_interact_prompt("Unlock Courtyard Gate with Key", self)
	else:
		hud_node.show_interact_prompt("Courtyard Gate [Locked - Key Required]", self)

func _try_unlock() -> void:
	if GameManager.has_item("brass_key"):
		_unlock_gate()
	else:
		GameManager.subtitle_requested.emit(
			"Saad",
			"It's padlocked with heavy chain. I need to find the brass key mentioned in Hridy's letter.",
			3.8
		)

func _unlock_gate() -> void:
	is_unlocked = true
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	if sfx_player and is_inside_tree():
		sfx_player.stream = SOUND_UNLOCK
		sfx_player.play()
	
	# Open door smoothly
	var t := create_tween().set_parallel(true)
	t.tween_property(door_pivot, "rotation:y", deg_to_rad(-105.0), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Disable physics blocker
	if blocker_collision:
		blocker_collision.set_deferred("disabled", true)
	
	GameManager.advance_objective(
		7,
		"03:00 AM — Courtyard Gate Unlocked",
		"Unlocked the iron gate. The courtyard path is open. Hridy is somewhere inside."
	)
	
	GameManager.play_saad_voice(
		"",
		"The lock gave way! Hridy, are you in here?!",
		4.0
	)
