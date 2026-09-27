extends Node3D

# Interactive World Clue: Courtyard Brass Key
# Found outside the Abandoned Corner Shop.

@export var prompt_text: String = "Take Rusted Brass Key"

@onready var area: Area3D = $Area3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

var player_in_range: bool = false
var hud_node: Node = null
var is_collected: bool = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not is_collected and mesh:
		mesh.rotate_y(1.4 * delta)
		mesh.position.y = 0.85 + sin(Time.get_ticks_msec() * 0.0035) * 0.03

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
		"id": "brass_key",
		"name": "Rusted Brass Key",
		"category": "Key Items",
		"icon_symbol": "🗝",
		"desc": "A heavy antique brass key stamped with 'Apt Courtyard Gate'. Stained with damp greenish patina. Unlocks the iron gate to the brick apartment courtyard.",
		"usable": true,
		"examinable": true
	})
	
	GameManager.advance_objective(
		6,
		"02:52 AM — Courtyard Key Retrieved",
		"Retrieved the brass key from the corner shop counter. Now I can unlock the gate leading into the brick apartment courtyard."
	)
	
	GameManager.play_saad_voice(
		"",
		"Found the courtyard gate key. Hold on Hridy, I am coming.",
		4.2
	)
	
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.2)
	t.tween_callback(queue_free)
