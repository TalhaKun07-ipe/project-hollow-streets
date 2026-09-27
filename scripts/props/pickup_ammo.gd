extends Node3D

# World Pickup: 9mm Ammunition Box
# Can spawn in random places across streets, alleys, and hospital corridors.
# Shows on Minimap radar until collected.

@export var ammo_amount: int = 6
@export var prompt_text: String = "Take 9mm Ammunition (+6)"
@export var marker_id: String = ""

@onready var area: Area3D = $Area3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var player_in_range: bool = false
var hud_node: Node = null
var is_collected: bool = false

func _ready() -> void:
	if marker_id == "":
		marker_id = "ammo_" + str(get_instance_id())
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	_register_with_minimap()

func _process(delta: float) -> void:
	if not is_collected and mesh:
		mesh.rotate_y(1.5 * delta)
		mesh.position.y = 0.12 + sin(Time.get_ticks_msec() * 0.004) * 0.025

func _register_with_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("register_item_marker"):
		minimap.register_item_marker(marker_id, global_position, "📦 9mm Ammo", Color(0.3, 0.9, 0.5))

func _unregister_from_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("unregister_item_marker"):
		minimap.unregister_item_marker(marker_id)

func _unhandled_input(event: InputEvent) -> void:
	if is_collected or not player_in_range:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
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
	
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("add_ammo"):
		player.add_ammo(ammo_amount)
	
	if hud_node and hud_node.has_method("show_notification"):
		hud_node.show_notification("AMMUNITION FOUND", "+%d 9mm Rounds" % ammo_amount)
	
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.2)
	t.tween_callback(queue_free)
