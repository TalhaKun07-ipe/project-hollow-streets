extends Control

# In-game HUD Controller
# Handles objective display, objective update notifications,
# interactive [E] prompts, and dialogue subtitles.

@onready var objective_title_lbl: Label = $ObjectiveCard/Margin/VBox/TitleLabel
@onready var objective_desc_lbl: Label = $ObjectiveCard/Margin/VBox/DescLabel
@onready var notif_panel: Panel = $NotifBanner
@onready var notif_title_lbl: Label = $NotifBanner/NotifTitle
@onready var subtitle_panel: Panel = $SubtitleBanner
@onready var subtitle_speaker_lbl: Label = $SubtitleBanner/Margin/VBox/Speaker
@onready var subtitle_text_lbl: Label = $SubtitleBanner/Margin/VBox/Text
@onready var interact_panel: Panel = $InteractPrompt
@onready var interact_label: Label = $InteractPrompt/PromptText
@onready var objective_card: Panel = $ObjectiveCard
@onready var minimap_ui: Control = get_node_or_null("MinimapUI")
@onready var cinematic_bars: Control = get_node_or_null("CinematicBars")
@onready var top_bar: ColorRect = get_node_or_null("CinematicBars/TopBar")
@onready var bottom_bar: ColorRect = get_node_or_null("CinematicBars/BottomBar")
@onready var skip_hint: Label = get_node_or_null("CinematicBars/SkipHint")
@onready var victory_panel: Control = $VictoryScreen
@onready var play_again_btn: Button = get_node_or_null("VictoryScreen/VBox/BtnBox/PlayAgainBtn")
@onready var main_menu_btn: Button = get_node_or_null("VictoryScreen/VBox/BtnBox/MainMenuBtn")
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

@onready var type_tick_player: AudioStreamPlayer = get_node_or_null("TypeTickPlayer")

const SOUND_NOTIF: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const SOUND_PICKUP: AudioStream = preload("res://assets/audio/footstep_land.wav")
const SOUND_TYPE_TICK: AudioStream = preload("res://assets/audio/text_tick.wav")

var subtitle_tween: Tween = null
var notif_tween: Tween = null
var cutscene_tween: Tween = null
var current_prompt_target: Node = null
var current_typing_id: int = 0
var is_typing_subtitle: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if is_typing_subtitle:
		if event.is_action_pressed("interact") or event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_E or event.keycode == KEY_ENTER)):
			is_typing_subtitle = false
			subtitle_text_lbl.visible_characters = -1

func _ready() -> void:
	notif_panel.modulate.a = 0.0
	subtitle_panel.modulate.a = 0.0
	interact_panel.modulate.a = 0.0
	if victory_panel:
		victory_panel.visible = false
	
	GameManager.objective_updated.connect(_on_objective_updated)
	GameManager.subtitle_requested.connect(_show_subtitle)
	GameManager.game_won.connect(_on_game_won)
	
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again_pressed)
		play_again_btn.mouse_entered.connect(func(): _play_sound(SOUND_NOTIF, 1.2))
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
		main_menu_btn.mouse_entered.connect(func(): _play_sound(SOUND_NOTIF, 1.2))
	
	_refresh_objective()

func _refresh_objective() -> void:
	var cur := GameManager.get_current_objective()
	objective_title_lbl.text = cur.get("title", "Find Hridy").to_upper()
	objective_desc_lbl.text = cur.get("desc", "")

func _on_objective_updated(_index: int, title: String, desc: String) -> void:
	_refresh_objective()
	_show_notification("OBJECTIVE UPDATED", title)

func _show_notification(header: String, text: String) -> void:
	notif_title_lbl.text = header + ": " + text.to_upper()
	if notif_tween and notif_tween.is_valid():
		notif_tween.kill()
	
	_play_sound(SOUND_NOTIF, 1.25)
	
	notif_tween = create_tween()
	notif_tween.tween_property(notif_panel, "modulate:a", 1.0, 0.3)
	notif_tween.tween_interval(3.0)
	notif_tween.tween_property(notif_panel, "modulate:a", 0.0, 0.6)

func _show_subtitle(speaker: String, text: String, duration: float) -> void:
	current_typing_id += 1
	var this_id := current_typing_id
	
	if speaker != "":
		subtitle_speaker_lbl.visible = true
		subtitle_speaker_lbl.text = "[ " + speaker.to_upper() + " ]"
	else:
		subtitle_speaker_lbl.visible = false
	
	subtitle_text_lbl.text = text
	subtitle_text_lbl.visible_characters = 0
	is_typing_subtitle = true
	
	if subtitle_tween and subtitle_tween.is_valid():
		subtitle_tween.kill()
	
	subtitle_panel.visible = true
	var fade_in := create_tween()
	fade_in.tween_property(subtitle_panel, "modulate:a", 1.0, 0.15)
	
	_run_sh1_typewriter(this_id, text, duration)

func _run_sh1_typewriter(id: int, text: String, duration: float) -> void:
	var total_chars := text.length()
	for i in range(1, total_chars + 1):
		if id != current_typing_id:
			return
		
		if not is_typing_subtitle:
			subtitle_text_lbl.visible_characters = -1
			break
		
		subtitle_text_lbl.visible_characters = i
		var ch := text[i - 1]
		
		if ch != " " and ch != "\t" and ch != "\n":
			_play_text_tick()
		
		var char_delay: float = 0.035
		if ch in [".", "!", "?"]:
			char_delay = 0.24
		elif ch in [",", ";", ":"]:
			char_delay = 0.14
		elif ch == "-":
			char_delay = 0.1
		
		await get_tree().create_timer(char_delay).timeout
		if id != current_typing_id:
			return
	
	is_typing_subtitle = false
	subtitle_text_lbl.visible_characters = -1
	
	await get_tree().create_timer(duration).timeout
	if id != current_typing_id:
		return
	
	subtitle_tween = create_tween()
	subtitle_tween.tween_property(subtitle_panel, "modulate:a", 0.0, 0.45)
	subtitle_tween.tween_callback(func():
		if id == current_typing_id:
			subtitle_panel.visible = false
	)

func _play_text_tick() -> void:
	if type_tick_player and is_inside_tree():
		type_tick_player.stream = SOUND_TYPE_TICK
		type_tick_player.pitch_scale = randf_range(0.92, 1.08)
		type_tick_player.volume_db = -12.0
		type_tick_player.play()

func show_interact_prompt(text: String, source_node: Node) -> void:
	current_prompt_target = source_node
	interact_label.text = "[E] " + text
	var t := create_tween()
	t.tween_property(interact_panel, "modulate:a", 1.0, 0.15)

func hide_interact_prompt(source_node: Node) -> void:
	if current_prompt_target == source_node or source_node == null:
		current_prompt_target = null
		var t := create_tween()
		t.tween_property(interact_panel, "modulate:a", 0.0, 0.15)

func _on_game_won() -> void:
	if victory_panel:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		victory_panel.visible = true
		victory_panel.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(victory_panel, "modulate:a", 1.0, 1.2)

func _on_play_again_pressed() -> void:
	_play_sound(SOUND_NOTIF, 1.0)
	GameManager.start_new_game()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	_play_sound(SOUND_NOTIF, 0.9)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	if sfx_player and is_inside_tree():
		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch
		sfx_player.play()

func show_cinematic_bars(duration: float = 0.8) -> void:
	if not cinematic_bars or not top_bar or not bottom_bar:
		return
	if cutscene_tween and cutscene_tween.is_valid():
		cutscene_tween.kill()
	
	cinematic_bars.visible = true
	cinematic_bars.modulate.a = 1.0
	top_bar.offset_bottom = 0.0
	bottom_bar.offset_top = 0.0
	if skip_hint:
		skip_hint.visible = true
		skip_hint.modulate.a = 0.0
	
	# Hide standard HUD elements while cinematic letterbox is active
	if objective_card:
		objective_card.modulate.a = 0.0
	if minimap_ui:
		minimap_ui.modulate.a = 0.0
	
	cutscene_tween = create_tween().set_parallel(true)
	cutscene_tween.tween_property(top_bar, "offset_bottom", 90.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cutscene_tween.tween_property(bottom_bar, "offset_top", -90.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if skip_hint:
		cutscene_tween.tween_property(skip_hint, "modulate:a", 0.6, duration * 1.5)

func fade_out_cinematic_bars(duration: float = 1.2) -> void:
	if not cinematic_bars or not top_bar or not bottom_bar:
		return
	if cutscene_tween and cutscene_tween.is_valid():
		cutscene_tween.kill()
	
	cutscene_tween = create_tween().set_parallel(true)
	# Smoothly slide and fade out cinematic bars, returning to full screen
	cutscene_tween.tween_property(top_bar, "offset_bottom", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cutscene_tween.tween_property(bottom_bar, "offset_top", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cutscene_tween.tween_property(cinematic_bars, "modulate:a", 0.0, duration)
	
	# Smoothly bring in gameplay HUD and minimap radar
	if objective_card:
		cutscene_tween.tween_property(objective_card, "modulate:a", 1.0, duration * 0.9)
	if minimap_ui:
		cutscene_tween.tween_property(minimap_ui, "modulate:a", 1.0, duration * 0.9)
	
	cutscene_tween.chain().tween_callback(func():
		cinematic_bars.visible = false
	)
