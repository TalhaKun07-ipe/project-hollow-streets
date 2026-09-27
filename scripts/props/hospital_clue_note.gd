extends Node3D

# Heisenberg Hospital Clue Note / Medical Document (Silent Hill 2 Brookhaven style)
# Provides immersive atmospheric clues guiding Saad floor by floor to find Hridy.

@export var clue_title: String = "Nurse's Logbook"
@export_multiline var clue_content: String = "Patient Hridy was seen fleeing upstairs toward the 2nd Floor Wards."
@export var prompt_text: String = "Read Nurse's Logbook"
@export var marker_id: String = "clue_hospital_memo"
@export var journal_header: String = "Heisenberg Hospital Document"

@onready var area: Area3D = $Area3D
@onready var mesh: Node3D = $DocModel
@onready var light: OmniLight3D = $OmniLight3D

const SOUND_PAGE: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")

var player_in_range: bool = false
var hud_node: Node = null
var has_been_read: bool = false

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	_register_with_minimap()

func _process(delta: float) -> void:
	if mesh and not has_been_read:
		mesh.rotate_y(1.2 * delta)
		mesh.position.y = 0.05 + sin(Time.get_ticks_msec() * 0.003) * 0.02

func _register_with_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("register_item_marker"):
		minimap.register_item_marker(marker_id, global_position, "📋 " + clue_title, Color(0.3, 0.85, 1.0))

func _unregister_from_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("unregister_item_marker"):
		minimap.unregister_item_marker(marker_id)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		_read_note()

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	player_in_range = true
	hud_node = get_tree().root.find_child("ObjectiveHUD", true, false)
	if hud_node and hud_node.has_method("show_interact_prompt"):
		hud_node.show_interact_prompt(prompt_text, self)

func _on_body_exited(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)

func _read_note() -> void:
	has_been_read = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.subtitle_requested.emit(clue_title, clue_content, 7.0)
		gm.add_journal_entry(journal_header + ": " + clue_title, clue_content)
	
	if hud_node and hud_node.has_method("show_notification"):
		hud_node.show_notification("DOCUMENT READ", clue_title)
	
	_unregister_from_minimap()
