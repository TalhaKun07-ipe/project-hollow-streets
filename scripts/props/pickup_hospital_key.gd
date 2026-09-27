extends Node3D

# World Pickup: Hospital Key Item
# Unlocks respective hospital stairwells/doors to reach the top floor.
# Automatically registers on Minimap radar until collected.

@export var key_id: String = "hosp_key_floor2"
@export var key_name: String = "2nd Floor Ward Key"
@export var key_desc: String = "A brass hospital key tagged '2F Ward'. Unlocks the stairwell gate to the second floor."
@export var marker_id: String = ""
@export var prompt_text: String = "Take 2nd Floor Ward Key"

@onready var area: Area3D = $Area3D
@onready var mesh: Node3D = $KeyModel
@onready var light: OmniLight3D = $OmniLight3D

var player_in_range: bool = false
var hud_node: Node = null
var is_collected: bool = false

func _ready() -> void:
	if marker_id == "":
		marker_id = "key_" + key_id
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	_register_with_minimap()

func _process(delta: float) -> void:
	if not is_collected and mesh:
		mesh.rotate_y(2.0 * delta)
		mesh.position.y = 0.08 + sin(Time.get_ticks_msec() * 0.005) * 0.03

func _register_with_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("register_item_marker"):
		minimap.register_item_marker(marker_id, global_position, "🔑 " + key_name, Color(1.0, 0.82, 0.2))

func _unregister_from_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("unregister_item_marker"):
		minimap.unregister_item_marker(marker_id)

func _unhandled_input(event: InputEvent) -> void:
	if is_collected or not player_in_range:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		_collect()

func _on_body_entered(body: Node3D) -> void:
	if is_collected or not (body is CharacterBody3D):
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

func _collect() -> void:
	is_collected = true
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	_unregister_from_minimap()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.add_item({
			"id": key_id,
			"name": key_name,
			"category": "Keys",
			"icon_symbol": "🔑",
			"desc": key_desc,
			"usable": true,
			"examinable": true
		})
		gm.subtitle_requested.emit(
			"Saad",
			"Found the %s! Now I can unlock the next floor." % key_name,
			3.5
		)
	
	if hud_node and hud_node.has_method("show_notification"):
		hud_node.show_notification("HOSPITAL KEY FOUND", key_name)
	
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.25)
	t.tween_callback(queue_free)
