extends Node3D

# Interactive World Clue: Hridy's Abandoned Sedan
# Parked at the northern avenue edge where Hridy had to abandon her vehicle.

@export var prompt_text: String = "Inspect Abandoned Sedan"

@onready var area: Area3D = $Area3D
@onready var hazard_light: OmniLight3D = get_node_or_null("HazardLight")
@onready var item_mesh: MeshInstance3D = get_node_or_null("ClueNote")

var player_in_range: bool = false
var hud_node: Node = null
var is_inspected: bool = false
var blink_timer: float = 0.0

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Pulsing hazard warning light on the car
	blink_timer += delta * 4.0
	if hazard_light:
		hazard_light.light_energy = 2.2 if fmod(blink_timer, 2.0) < 1.0 else 0.2
	
	if not is_inspected and item_mesh:
		item_mesh.position.y = 0.72 + sin(Time.get_ticks_msec() * 0.004) * 0.03

func _unhandled_input(event: InputEvent) -> void:
	if is_inspected or not player_in_range:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_inspect_car()

func _on_body_entered(body: Node3D) -> void:
	if is_inspected or not (body is CharacterBody3D):
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

func _inspect_car() -> void:
	is_inspected = true
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	GameManager.add_item({
		"id": "hridy_diary_note",
		"name": "Hridy's Travel Note",
		"category": "Documents",
		"icon_symbol": "📄",
		"desc": "A hurried note found on the driver's seat: 'Engine died in the fog. Heard heavy scraping sounds from the street corner. Heading for the intersection.'",
		"usable": true,
		"examinable": true
	})
	
	GameManager.advance_objective(
		2,
		"02:22 AM — Hridy's Abandoned Car",
		"Inspected Hridy's car at the north end of the avenue. The keys were still in the ignition. She abandoned it and fled south toward the main intersection."
	)
	
	GameManager.play_saad_voice(
		"",
		"Her car is abandoned... the engine is still warm. She ran down towards the central intersection.",
		4.5
	)
	
	if item_mesh:
		var t := create_tween()
		t.tween_property(item_mesh, "scale", Vector3.ZERO, 0.25)
		t.tween_callback(func(): item_mesh.visible = false)
