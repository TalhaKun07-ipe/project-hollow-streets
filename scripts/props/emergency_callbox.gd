extends Node3D

# Interactive World Clue: West Street Emergency Callbox
# A vintage weathered callbox on the west sidewalk containing a high-voltage maintenance fuse.

@export var prompt_text: String = "Inspect Emergency Callbox"

@onready var area: Area3D = $Area3D
@onready var beacon_light: OmniLight3D = get_node_or_null("BeaconLight")
@onready var item_mesh: MeshInstance3D = get_node_or_null("FuseMesh")

var player_in_range: bool = false
var hud_node: Node = null
var is_collected: bool = false
var pulse_timer: float = 0.0

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	pulse_timer += delta * 5.0
	if beacon_light:
		beacon_light.light_energy = 1.8 if fmod(pulse_timer, 2.0) < 1.0 else 0.3
	
	if not is_collected and item_mesh:
		item_mesh.rotate_y(1.5 * delta)

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
	
	GameManager.add_item({
		"id": "maintenance_fuse",
		"name": "Industrial Breaker Fuse",
		"category": "Key Items",
		"icon_symbol": "⚡",
		"desc": "A heavy-duty 400V ceramic fuse stamped 'MUNICIPAL POWER'. Found on the shelf of the emergency callbox. Can be fitted into the substation breaker box.",
		"usable": true,
		"examinable": true
	})
	
	GameManager.advance_objective(
		4,
		"02:38 AM — Emergency Callbox Searched",
		"Investigated the red emergency telephone box down the western street. Recovered a heavy electrical breaker fuse. I should check the alleyway behind the commercial tower for the power breaker."
	)
	
	GameManager.play_saad_voice(
		"",
		"An emergency high-voltage fuse. The alley breaker station behind the commercial tower must need this.",
		4.5
	)
	
	if item_mesh:
		var t := create_tween()
		t.tween_property(item_mesh, "scale", Vector3.ZERO, 0.2)
		t.tween_callback(func(): item_mesh.visible = false)
