extends Node3D

# Hridy NPC & Rescue Climax Controller
# Located in the secluded apartment courtyard alcove.

@export var prompt_text: String = "Talk to Hridy"

@onready var area: Area3D = $Area3D
@onready var lantern_light: OmniLight3D = $Lantern/OmniLight3D
@onready var anim_player: AnimationPlayer = get_node_or_null("HridyModel/AnimationPlayer")

var player_in_range: bool = false
var hud_node: Node = null
var is_rescued: bool = false

func _ready() -> void:
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if is_rescued or not player_in_range:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_talk()

func _on_body_entered(body: Node3D) -> void:
	if is_rescued or not (body is CharacterBody3D):
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

func _talk() -> void:
	is_rescued = true
	player_in_range = false
	if hud_node and hud_node.has_method("hide_interact_prompt"):
		hud_node.hide_interact_prompt(self)
	
	var gm = GameManager
	if gm:
		gm.advance_objective(
			8,
			"03:15 AM — Hridy Rescued",
			"Found Hridy safe on the top floor of the Grand Hospital. The nightmare of Hollow Streets is finally over."
		)
		gm.subtitle_requested.emit(
			"Hridy",
			"Saad! You found me! I was so terrified up here on the top floor in the dark... I knew you would come!",
			5.0
		)
		get_tree().create_timer(3.5).timeout.connect(func():
			if gm:
				gm.play_saad_voice(
					"",
					"Hridy! You are safe. Thank God you are okay. Let us get out of this town.",
					4.5
				)
		)
		get_tree().create_timer(7.5).timeout.connect(func():
			if gm:
				gm.game_won.emit()
		)
