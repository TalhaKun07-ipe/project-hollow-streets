extends Control

# Silent Hill style Survival Inventory UI
# Allows inspecting items, reading documents (links to Journal),
# and interacting with equipment (torch, keys, supplies).

signal request_open_journal()
signal request_toggle_torch()

@onready var item_list_vbox: VBoxContainer = $Panel/HBoxContainer/LeftCol/ScrollContainer/ItemListVBox
@onready var item_title_lbl: Label = $Panel/HBoxContainer/RightCol/ItemHeader/ItemTitle
@onready var item_category_lbl: Label = $Panel/HBoxContainer/RightCol/ItemHeader/ItemCategory
@onready var item_icon_lbl: Label = $Panel/HBoxContainer/RightCol/IconBox/ItemIcon
@onready var item_desc_lbl: Label = $Panel/HBoxContainer/RightCol/DescMargin/ItemDesc
@onready var use_btn: Button = $Panel/HBoxContainer/RightCol/ActionsBox/UseBtn
@onready var examine_btn: Button = $Panel/HBoxContainer/RightCol/ActionsBox/ExamineBtn
@onready var close_btn: Button = $Panel/HBoxContainer/RightCol/ActionsBox/CloseBtn
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

const SOUND_SELECT: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const SOUND_USE: AudioStream = preload("res://assets/audio/flashlight_click_off.wav")

var is_open: bool = false
var selected_item_id: String = ""

func _ready() -> void:
	visible = false
	use_btn.pressed.connect(_on_use_pressed)
	examine_btn.pressed.connect(_on_examine_pressed)
	close_btn.pressed.connect(close_inventory)
	
	GameManager.item_added.connect(func(_it): _rebuild_item_list())
	GameManager.item_removed.connect(func(_id): _rebuild_item_list())

func open_inventory() -> void:
	is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sound(SOUND_SELECT, 1.0)
	_rebuild_item_list()
	if GameManager.inventory.size() > 0:
		_select_item(GameManager.inventory[0]["id"])
	GameManager.inventory_toggled.emit(true)

func close_inventory() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_play_sound(SOUND_USE, 0.9)
	if GameManager.is_game_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameManager.inventory_toggled.emit(false)

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("toggle_inventory") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_I or event.keycode == KEY_TAB)):
		get_viewport().set_input_as_handled()
		close_inventory()

func _rebuild_item_list() -> void:
	if not item_list_vbox:
		return
	for c in item_list_vbox.get_children():
		c.queue_free()
	
	for item in GameManager.inventory:
		var btn := Button.new()
		btn.text = " " + item.get("icon_symbol", "•") + "  " + item["name"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 14)
		
		# Selected styling
		if item["id"] == selected_item_id:
			btn.modulate = Color(1.2, 0.9, 0.8, 1.0)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85, 0.9)
		
		var it_id: String = item["id"]
		btn.pressed.connect(func(): _select_item(it_id))
		item_list_vbox.add_child(btn)

func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	_play_sound(SOUND_SELECT, 1.1)
	
	# Find item
	var found_item: Dictionary = {}
	for it in GameManager.inventory:
		if it["id"] == item_id:
			found_item = it
			break
	
	if found_item.is_empty():
		return
	
	item_title_lbl.text = found_item["name"]
	item_category_lbl.text = "CATEGORY: " + found_item.get("category", "Item").to_upper()
	item_icon_lbl.text = found_item.get("icon_symbol", "📦")
	item_desc_lbl.text = found_item["desc"]
	
	# Action buttons configuration
	if found_item["id"] == "hridy_letter":
		use_btn.text = "READ IN JOURNAL"
		examine_btn.text = "EXAMINE NOTE"
	elif found_item["id"] == "flashlight":
		use_btn.text = "TOGGLE ON / OFF"
		examine_btn.text = "INSPECT CASING"
	elif found_item["id"] == "health_drink":
		use_btn.text = "DRINK TONIC"
		examine_btn.text = "EXAMINE BOTTLE"
	elif found_item["id"] == "brass_key":
		use_btn.text = "EQUIP KEY"
		examine_btn.text = "INSPECT KEY"
	elif found_item["id"] == "silver_locket":
		use_btn.text = "OPEN LOCKET"
		examine_btn.text = "EXAMINE ENGRAVING"
	else:
		use_btn.text = "USE"
		examine_btn.text = "EXAMINE"
	
	# Refresh button highlight
	for b in item_list_vbox.get_children():
		if b is Button:
			if b.text.contains(found_item["name"]):
				b.modulate = Color(1.2, 0.9, 0.8, 1.0)
			else:
				b.modulate = Color(0.85, 0.85, 0.85, 0.9)

func _on_use_pressed() -> void:
	if selected_item_id == "":
		return
	
	_play_sound(SOUND_USE, 1.05)
	
	if selected_item_id == "hridy_letter":
		close_inventory()
		request_open_journal.emit()
	elif selected_item_id == "flashlight":
		request_toggle_torch.emit()
		close_inventory()
	elif selected_item_id == "health_drink":
		GameManager.subtitle_requested.emit("Saad", "The warm herbal tonic soothes the chilling dread of the fog.", 3.0)
		GameManager.remove_item("health_drink")
		if GameManager.inventory.size() > 0:
			_select_item(GameManager.inventory[0]["id"])
	elif selected_item_id == "brass_key":
		GameManager.subtitle_requested.emit("Saad", "The brass key stamped 'Apt Courtyard'. I should find the chained gate.", 3.0)
	elif selected_item_id == "silver_locket":
		GameManager.subtitle_requested.emit("Saad", "Hridy's portrait is inside. 'Forever in the light — Hridy'. I won't let her down.", 3.5)

func _on_examine_pressed() -> void:
	if selected_item_id == "":
		return
	_play_sound(SOUND_SELECT, 1.2)
	if selected_item_id == "hridy_letter":
		close_inventory()
		request_open_journal.emit()
	elif selected_item_id == "flashlight":
		GameManager.subtitle_requested.emit("Saad", "Heavy machined aluminum casing. Battery is fully charged. Key [F] toggles beam.", 3.0)
	elif selected_item_id == "brass_key":
		GameManager.subtitle_requested.emit("Saad", "An old brass key found near the corner shop. Matches the apartment courtyard gate.", 3.0)
	elif selected_item_id == "silver_locket":
		GameManager.subtitle_requested.emit("Saad", "The silver chain snapped under haste. Hridy was fleeing when she lost this.", 3.2)
	elif selected_item_id == "health_drink":
		GameManager.subtitle_requested.emit("Saad", "Local apothecary blend. Has an earthy, bitter fragrance.", 2.8)

func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	if sfx_player and is_inside_tree():
		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch
		sfx_player.play()
