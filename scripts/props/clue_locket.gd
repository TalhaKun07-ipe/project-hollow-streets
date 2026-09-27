extends Node3D

# Interactive World Clue: Hridy's Silver Locket
# Dropped at the central intersection during her escape.

@export var prompt_text: String = "Inspect Silver Locket"

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
		mesh.rotate_y(1.2 * delta)
		# Subtle gentle bobbing
		mesh.position.y = 0.12 + sin(Time.get_ticks_msec() * 0.003) * 0.04

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
		"id": "silver_locket",
		"name": "Hridy's Silver Locket",
		"category": "Key Items",
		"icon_symbol": "📿",
		"desc": "A delicate silver locket with a snapped chain. Inside is a miniature photo of Hridy. Dropped in the crosswalk when she fled into the mist.",
		"usable": true,
		"examinable": true
	})
	
	GameManager.advance_objective(
		3,
		"02:30 AM — Hridy's Locket Found",
		"Found Hridy's silver locket dropped at the central crossing. She fled east, but street security gates are locked. I need to check the callbox on West Street for utility access."
	)
	
	GameManager.play_saad_voice(
		"",
		"Her silver locket... she never takes this off. She must have fled east into the cross street.",
		4.5
	)
	
	# Fade out and remove
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.2)
	t.tween_callback(queue_free)
