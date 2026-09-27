extends Node3D

# World Pickup: Service Handgun
# Randomly spawns in one of several atmospheric urban locations.
# Shows on Minimap radar until acquired.

@export var prompt_text: String = "Take Service Handgun"
@export var random_spawn: bool = true

const SPAWN_LOCATIONS: Array[Vector3] = [
	Vector3(-3.2, 0.85, -92.5),  # On the hood of Hridy's abandoned car
	Vector3(17.8, 0.45, 14.5),    # On the bench outside the Corner Shop
	Vector3(-62.5, 0.85, -8.5),   # Inside the emergency callbox alcove
	Vector3(-24.5, 0.45, -63.5),  # On a wooden crate by the alley substation
]

@onready var area: Area3D = $Area3D
@onready var glow_light: OmniLight3D = $GlowLight
@onready var mesh_root: Node3D = $GunModel

var player_in_range: bool = false
var hud_node: Node = null
var is_collected: bool = false

func _ready() -> void:
	if random_spawn and SPAWN_LOCATIONS.size() > 0:
		var idx := randi() % SPAWN_LOCATIONS.size()
		global_position = SPAWN_LOCATIONS[idx]
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	# Register with Minimap
	_register_with_minimap()

func _process(delta: float) -> void:
	if not is_collected and mesh_root:
		mesh_root.rotate_y(1.2 * delta)
		mesh_root.position.y = 0.08 + sin(Time.get_ticks_msec() * 0.003) * 0.03

func _register_with_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("register_item_marker"):
		minimap.register_item_marker("gun", global_position, "🔫 Service Handgun", Color(1.0, 0.8, 0.2))

func _unregister_from_minimap() -> void:
	var minimap = get_tree().root.find_child("MinimapUI", true, false)
	if minimap and minimap.has_method("unregister_item_marker"):
		minimap.unregister_item_marker("gun")

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
	
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.add_item({
			"id": "handgun",
			"name": "9mm Service Handgun",
			"category": "Weapons",
			"icon_symbol": "🔫",
			"desc": "A rugged semi-automatic pistol. 6-round capacity. Press [1] or [G] to equip/holster, [Left Mouse] to fire, [R] to reload.",
			"usable": true,
			"examinable": true
		})
	
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("unlock_gun"):
		player.unlock_gun()
	
	if gm:
		gm.subtitle_requested.emit(
			"Saad",
			"A police issue 9mm handgun. Still loaded. I can equip it with [1] or [G] to defend myself.",
			4.5
		)
	
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.2)
	t.tween_callback(queue_free)
