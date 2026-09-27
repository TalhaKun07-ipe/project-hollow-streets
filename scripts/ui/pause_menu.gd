extends Control

# Project Hollow Streets - Silent Hill Style Pause Menu Controller
# Pauses the game tree, manages audio & camera settings,
# and provides smooth navigation between menus.

@onready var menu_vbox: VBoxContainer = $Panel/VBoxContainer/MenuItems
@onready var resume_btn: Button = $Panel/VBoxContainer/MenuItems/ResumeBtn
@onready var journal_btn: Button = $Panel/VBoxContainer/MenuItems/JournalBtn
@onready var inventory_btn: Button = $Panel/VBoxContainer/MenuItems/InventoryBtn
@onready var fullscreen_btn: Button = $Panel/VBoxContainer/MenuItems/FullscreenBtn
@onready var restart_btn: Button = $Panel/VBoxContainer/MenuItems/RestartBtn
@onready var main_menu_btn: Button = $Panel/VBoxContainer/MenuItems/MainMenuBtn
@onready var quit_btn: Button = $Panel/VBoxContainer/MenuItems/QuitBtn
@onready var volume_slider: HSlider = find_child("VolumeSlider", true, false)
@onready var sensitivity_slider: HSlider = find_child("SensitivitySlider", true, false)
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

const SOUND_HOVER: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const SOUND_SELECT: AudioStream = preload("res://assets/audio/flashlight_click_off.wav")

var is_paused: bool = false
var buttons: Array[Button] = []
var selected_btn_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0

	resume_btn.pressed.connect(close_pause)
	journal_btn.pressed.connect(_on_journal)
	inventory_btn.pressed.connect(_on_inventory)
	fullscreen_btn.pressed.connect(_on_fullscreen)
	restart_btn.pressed.connect(_on_restart)
	main_menu_btn.pressed.connect(_on_main_menu)
	quit_btn.pressed.connect(_on_quit)

	# Setup settings sliders
	if volume_slider:
		volume_slider.value = GameManager.master_volume
		volume_slider.value_changed.connect(func(v: float):
			GameManager.set_master_volume(v)
		)

	if sensitivity_slider:
		sensitivity_slider.value = GameManager.mouse_sensitivity
		sensitivity_slider.value_changed.connect(func(v: float):
			GameManager.set_mouse_sensitivity(v)
		)

	# Collect menu action buttons for selection styling
	buttons = [
		resume_btn,
		journal_btn,
		inventory_btn,
		fullscreen_btn,
		restart_btn,
		main_menu_btn,
		quit_btn
	]

	for i in range(buttons.size()):
		var b: Button = buttons[i]
		var idx: int = i
		b.mouse_entered.connect(func(): _select_button(idx))
		b.focus_entered.connect(func(): _select_button(idx))

	_select_button(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var inv_ui = get_tree().root.find_child("InventoryUI", true, false)
		var jour_ui = get_tree().root.find_child("JournalUI", true, false)
		if (inv_ui and inv_ui.get("is_open")) or (jour_ui and jour_ui.get("is_open")):
			return # Let inventory or journal consume Esc first
		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause() -> void:
	if is_paused:
		close_pause()
	else:
		open_pause()

func open_pause() -> void:
	if is_paused:
		return
	is_paused = true
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sound(SOUND_HOVER, 1.0)
	
	# Update slider positions to active values
	if volume_slider:
		volume_slider.value = GameManager.master_volume
	if sensitivity_slider:
		sensitivity_slider.value = GameManager.mouse_sensitivity
	
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	_select_button(0)

func close_pause() -> void:
	if not is_paused:
		return
	is_paused = false
	_play_sound(SOUND_SELECT, 1.0)
	
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(func():
		visible = false
		get_tree().paused = false
		if GameManager.is_game_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	)

func _select_button(idx: int) -> void:
	selected_btn_idx = idx
	_play_sound(SOUND_HOVER, 1.2)
	
	for i in range(buttons.size()):
		var b: Button = buttons[i]
		var base_name: String = b.get_meta("base_text", b.text)
		if not b.has_meta("base_text"):
			b.set_meta("base_text", b.text.replace("▶  ", "").strip_edges())
			base_name = b.get_meta("base_text")
		
		if i == idx:
			b.text = "▶  " + base_name
			b.add_theme_color_override("font_color", Color(0.96, 0.35, 0.25, 1.0))
		else:
			b.text = "    " + base_name
			b.add_theme_color_override("font_color", Color(0.8, 0.78, 0.75, 0.85))

func _on_journal() -> void:
	_play_sound(SOUND_SELECT, 1.0)
	close_pause()
	var jour_ui = get_tree().root.find_child("JournalUI", true, false)
	if jour_ui and jour_ui.has_method("open_journal"):
		jour_ui.open_journal()

func _on_inventory() -> void:
	_play_sound(SOUND_SELECT, 1.0)
	close_pause()
	var inv_ui = get_tree().root.find_child("InventoryUI", true, false)
	if inv_ui and inv_ui.has_method("open_inventory"):
		inv_ui.open_inventory()

func _on_fullscreen() -> void:
	_play_sound(SOUND_SELECT, 1.1)
	GameManager.toggle_fullscreen()

func _on_restart() -> void:
	_play_sound(SOUND_SELECT, 0.9)
	is_paused = false
	get_tree().paused = false
	GameManager.start_new_game()
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	_play_sound(SOUND_SELECT, 0.85)
	is_paused = false
	get_tree().paused = false
	GameManager.is_game_active = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit() -> void:
	_play_sound(SOUND_SELECT, 0.8)
	get_tree().quit()

func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	if sfx_player and is_inside_tree():
		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch
		sfx_player.play()
