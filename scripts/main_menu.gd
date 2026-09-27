extends Control

# Silent Hill 2 Inspired Main Menu Controller
# Hand-crafted psychological horror aesthetics:
# Asymmetrical left-aligned vintage typography, red blood pointer cursor,
# eerie hover sound effects, and smooth cinematic transitions.

@onready var menu_items_vbox: VBoxContainer = $MenuContainer/VBox/MenuItems
@onready var controls_card: Panel = $ControlsCard
@onready var journal_ui: Control = $JournalUI
@onready var fade_rect: ColorRect = $FadeOverlay
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer

const SOUND_HOVER: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const SOUND_SELECT: AudioStream = preload("res://assets/audio/flashlight_click_off.wav")

var menu_buttons: Array[Button] = []
var current_selected_idx: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	controls_card.visible = false
	
	# Initial fade in
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, 1.2)
	t.tween_callback(func(): fade_rect.visible = false)
	
	# Gather buttons
	for child in menu_items_vbox.get_children():
		if child is Button:
			menu_buttons.append(child)
	
	for i in range(menu_buttons.size()):
		var btn: Button = menu_buttons[i]
		var idx: int = i
		btn.mouse_entered.connect(func(): _select_index(idx))
		btn.focus_entered.connect(func(): _select_index(idx))
	
	# Connect specific actions
	var new_game_btn: Button = menu_buttons[0]
	var load_game_btn: Button = menu_buttons[1]
	var journal_btn: Button = menu_buttons[2]
	var controls_btn: Button = menu_buttons[3]
	var exit_btn: Button = menu_buttons[4]
	
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	journal_btn.pressed.connect(_on_journal)
	controls_btn.pressed.connect(_on_controls)
	exit_btn.pressed.connect(_on_exit)
	
	$ControlsCard/VBox/BackBtn.pressed.connect(func():
		_play_sound(SOUND_HOVER, 1.0)
		controls_card.visible = false
	)
	
	_select_index(0)

func _select_index(idx: int) -> void:
	current_selected_idx = idx
	_play_sound(SOUND_HOVER, 1.15)
	
	for i in range(menu_buttons.size()):
		var btn: Button = menu_buttons[i]
		var raw_name: String = btn.get_meta("base_text", btn.text)
		if not btn.has_meta("base_text"):
			btn.set_meta("base_text", btn.text.replace("▶  ", "").strip_edges())
			raw_name = btn.get_meta("base_text")
		
		if i == idx:
			btn.text = "▶  " + raw_name
			btn.add_theme_color_override("font_color", Color(0.96, 0.32, 0.25, 1.0))
		else:
			btn.text = "    " + raw_name
			btn.add_theme_color_override("font_color", Color(0.72, 0.70, 0.68, 0.85))

func _on_new_game() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_play_sound(SOUND_SELECT, 0.9)
	
	GameManager.start_new_game()
	
	fade_rect.visible = true
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.9)
	t.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

func _on_load_game() -> void:
	_play_sound(SOUND_HOVER, 0.85)
	var load_btn: Button = menu_buttons[1]
	load_btn.text = "▶  [ NO CASSETTE TAPE FOUND ]"
	get_tree().create_timer(1.8).timeout.connect(func():
		_select_index(current_selected_idx)
	)

func _on_journal() -> void:
	_play_sound(SOUND_SELECT, 1.0)
	if journal_ui and journal_ui.has_method("open_journal"):
		journal_ui.open_journal("letter")

func _on_controls() -> void:
	_play_sound(SOUND_SELECT, 1.0)
	controls_card.visible = true

func _on_exit() -> void:
	_play_sound(SOUND_SELECT, 0.8)
	get_tree().quit()

func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	if sfx_player and is_inside_tree():
		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch
		sfx_player.play()
