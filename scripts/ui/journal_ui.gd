extends Control

# Silent Hill style Journal Interface
# Contains Hridy's handwritten letter telling Saad to save her,
# and an ongoing investigation case log.

@onready var letter_tab_btn: Button = $Panel/VBoxContainer/TabBar/LetterTabBtn
@onready var log_tab_btn: Button = $Panel/VBoxContainer/TabBar/LogTabBtn
@onready var letter_container: ScrollContainer = $Panel/VBoxContainer/ContentArea/LetterScroll
@onready var log_container: ScrollContainer = $Panel/VBoxContainer/ContentArea/LogScroll
@onready var letter_text_label: Label = find_child("LetterText", true, false)
@onready var log_vbox: VBoxContainer = find_child("LogVBox", true, false)
@onready var close_btn: Button = $Panel/VBoxContainer/BottomBar/CloseBtn
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

const SOUND_PAGE: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const SOUND_CLOSE: AudioStream = preload("res://assets/audio/flashlight_click_off.wav")

var is_open: bool = false

func _ready() -> void:
	visible = false
	letter_tab_btn.pressed.connect(_show_letter)
	log_tab_btn.pressed.connect(_show_log)
	close_btn.pressed.connect(close_journal)
	
	letter_text_label.text = GameManager.HRIDY_LETTER_TEXT
	
	GameManager.journal_updated.connect(_refresh_log)
	_refresh_log()

func open_journal(tab: String = "letter") -> void:
	is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sound(SOUND_PAGE, 0.9)
	
	if tab == "log":
		_show_log()
	else:
		_show_letter()
	
	GameManager.journal_toggled.emit(true)

func close_journal() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_play_sound(SOUND_CLOSE, 1.0)
	
	# Only recapture mouse if in 3D game
	if GameManager.is_game_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	GameManager.journal_toggled.emit(false)

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("toggle_journal") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_J):
		get_viewport().set_input_as_handled()
		close_journal()

func _show_letter() -> void:
	_play_sound(SOUND_PAGE, 1.1)
	letter_container.visible = true
	log_container.visible = false
	letter_tab_btn.modulate = Color(1.0, 0.85, 0.7, 1.0)
	log_tab_btn.modulate = Color(0.6, 0.6, 0.6, 1.0)

func _show_log() -> void:
	_play_sound(SOUND_PAGE, 0.95)
	letter_container.visible = false
	log_container.visible = true
	letter_tab_btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
	log_tab_btn.modulate = Color(1.0, 0.85, 0.7, 1.0)
	_refresh_log()

func _refresh_log() -> void:
	if not log_vbox:
		return
	for c in log_vbox.get_children():
		c.queue_free()
	
	for entry in GameManager.journal_entries:
		var entry_box := VBoxContainer.new()
		entry_box.add_theme_constant_override("separation", 4)
		
		var title_lbl := Label.new()
		title_lbl.text = entry["title"]
		title_lbl.add_theme_color_override("font_color", Color(0.88, 0.45, 0.35, 1.0))
		title_lbl.add_theme_font_size_override("font_size", 16)
		entry_box.add_child(title_lbl)
		
		var body_lbl := Label.new()
		body_lbl.text = entry["content"]
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78, 0.95))
		body_lbl.add_theme_font_size_override("font_size", 14)
		entry_box.add_child(body_lbl)
		
		var sep := HSeparator.new()
		sep.modulate = Color(0.4, 0.35, 0.3, 0.5)
		entry_box.add_child(sep)
		
		log_vbox.add_child(entry_box)

func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	if sfx_player and is_inside_tree():
		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch
		sfx_player.play()
