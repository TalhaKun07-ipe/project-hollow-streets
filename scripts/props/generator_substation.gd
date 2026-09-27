extends Node3D

# Interactive Alleyway Electrical Breaker Substation
# Located in the alleyway behind the Commercial Tower. Requires Industrial Breaker Fuse.

@export var is_powered: bool = false

@onready var area: Area3D = $Area3D
@onready var status_light: OmniLight3D = get_node_or_null("StatusLight")
@onready var spark_light: OmniLight3D = get_node_or_null("SparkLight")
@onready var switch_handle: Node3D = get_node_or_null("SwitchHandle")
@onready var hum_player: AudioStreamPlayer3D = get_node_or_null("HumPlayer")

var player_in_range: bool = false
var hud_node: Node = null

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	if spark_light:
		spark_light.visible = false
	if status_light:
		status_light.light_color = Color(1.0, 0.15, 0.1) # Red initially

func _unhandled_input(event: InputEvent) -> void:
	if is_powered or not player_in_range:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_interact()

func _on_body_entered(body: Node3D) -> void:
	if is_powered or not (body is CharacterBody3D):
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
	if GameManager.has_item("maintenance_fuse"):
		hud_node.show_interact_prompt("Insert Fuse & Engage Breaker", self)
	else:
		hud_node.show_interact_prompt("Substation Breaker [Missing Fuse]", self)

func _interact() -> void:
	if GameManager.has_item("maintenance_fuse"):
		_restore_power()
	else:
		GameManager.subtitle_requested.emit(
			"Saad",
			"The main breaker socket is empty. I need to find a high-voltage fuse. Maybe the callbox on West Street has one.",
			4.0
		)

func _restore_power() -> void:
	is_powered = true
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	# Turn handle
	if switch_handle:
		var t := create_tween()
		t.tween_property(switch_handle, "rotation:x", deg_to_rad(-45.0), 0.3)
	
	# Electrical spark effect
	if spark_light:
		spark_light.visible = true
		spark_light.light_energy = 8.0
		var t2 := create_tween()
		t2.tween_property(spark_light, "light_energy", 0.0, 0.4)
		t2.tween_callback(func(): spark_light.visible = false)
	
	# Switch status light to Green
	if status_light:
		status_light.light_color = Color(0.2, 1.0, 0.3)
		status_light.light_energy = 2.5
	
	# Start hum audio
	if hum_player and is_inside_tree():
		hum_player.play()
	
	GameManager.advance_objective(
		5,
		"02:48 AM — Street Grid Power Restored",
		"Inserted the industrial fuse and engaged the breaker. High-voltage power hummed through the street conduits. The corner shop registers and doors should now be powered."
	)
	
	GameManager.play_saad_voice(
		"",
		"The breaker is humming. Main power is restored to the corner shop across the street.",
		4.2
	)
