extends Node3D

# Interactive Hospital Door Controller
# Supports single and double doors, lock keys, smooth swinging tween, and audio.

@export var door_name: String = "Hospital Door"
@export var required_key_id: String = "" # Empty if unlocked by default
@export var key_display_name: String = "Hospital Key"
@export var is_unlocked: bool = false
@export var is_open: bool = false
@export var double_door: bool = false
@export var swing_angle: float = 105.0

@onready var area: Area3D = $Area3D
@onready var door_pivot_left: Node3D = $PivotLeft
@onready var door_pivot_right: Node3D = get_node_or_null("PivotRight")
@onready var blocker_col: CollisionShape3D = $BlockerBody/CollisionShape3D
@onready var sfx_player: AudioStreamPlayer3D = $SFXPlayer3D

const SOUND_CREAK_OPEN: AudioStream = preload("res://audio/sfx/door/door_creak_open.wav")
const SOUND_UNLOCK: AudioStream = preload("res://audio/sfx/door/door_unlock.wav")
const SOUND_LOCKED: AudioStream = preload("res://audio/sfx/door/door_locked.wav")

var player_in_range: bool = false
var hud_node: Node = null
var is_animating: bool = false

func _ready() -> void:
	if required_key_id == "":
		is_unlocked = true
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_animating:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		_interact()

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
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
	
	if is_open:
		hud_node.hide_interact_prompt(self)
		return
	
	var gm = get_node_or_null("/root/GameManager")
	if not is_unlocked:
		if gm and gm.has_item(required_key_id):
			hud_node.show_interact_prompt("Unlock %s with [%s]" % [door_name, key_display_name], self)
		else:
			hud_node.show_interact_prompt("Locked [%s] — Search for %s" % [door_name, key_display_name], self)
	else:
		hud_node.show_interact_prompt("Open %s" % door_name, self)

func _interact() -> void:
	if is_open or is_animating:
		return
	
	var gm = get_node_or_null("/root/GameManager")
	if not is_unlocked:
		if gm and gm.has_item(required_key_id):
			_unlock_and_open()
		else:
			# Play locked rattle sound
			if sfx_player and is_inside_tree():
				sfx_player.stream = SOUND_LOCKED
				sfx_player.pitch_scale = randf_range(0.95, 1.05)
				sfx_player.play()
			if gm:
				gm.subtitle_requested.emit(
					"Saad",
					"It's locked tight. I need to find the %s." % key_display_name,
					3.2
				)
	else:
		_open_door()

func _unlock_and_open() -> void:
	is_unlocked = true
	is_animating = true
	
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	# Play unlock click
	if sfx_player and is_inside_tree():
		sfx_player.stream = SOUND_UNLOCK
		sfx_player.pitch_scale = 1.0
		sfx_player.play()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.subtitle_requested.emit(
			"Saad",
			"The %s unlocked the door!" % key_display_name,
			2.5
		)
	
	# Open shortly after unlock click
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_callback(_open_door)

func _open_door() -> void:
	is_open = true
	is_animating = true
	
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	if blocker_col:
		blocker_col.set_deferred("disabled", true)
	
	if sfx_player and is_inside_tree():
		sfx_player.stream = SOUND_CREAK_OPEN
		sfx_player.pitch_scale = randf_range(0.96, 1.04)
		sfx_player.play()
	
	var tw := create_tween().set_parallel(true)
	if door_pivot_left:
		tw.tween_property(door_pivot_left, "rotation:y", deg_to_rad(-swing_angle), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if door_pivot_right:
		tw.tween_property(door_pivot_right, "rotation:y", deg_to_rad(swing_angle), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tw.chain().tween_callback(func():
		is_animating = false
	)
