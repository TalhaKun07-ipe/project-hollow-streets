extends Node

# Project Hollow Streets - Master Game Manager & State Controller
# Manages objectives, inventory, journal, voice lines, and player UI state.

signal objective_updated(stage_index: int, stage_title: String, stage_desc: String)
signal item_added(item: Dictionary)
signal item_removed(item_id: String)
signal journal_updated()
signal inventory_toggled(is_open: bool)
signal journal_toggled(is_open: bool)
signal subtitle_requested(speaker: String, text: String, duration: float)
signal game_won()

# --- Objectives Definition ---
var objectives: Array[Dictionary] = [
	{
		"id": "stage_0",
		"title": "The Misty Avenue",
		"desc": "Investigate the deserted streets of Hollow Town. Search the stalled car down the northern avenue. (Press [J] for Journal, [I] for Inventory)",
		"completed": false
	},
	{
		"id": "stage_1",
		"title": "Hridy's Abandoned Car",
		"desc": "Inspect Hridy's stalled sedan at the northern avenue edge for clues about where she fled.",
		"completed": false
	},
	{
		"id": "stage_2",
		"title": "A Clue in the Mist",
		"desc": "Follow the trail south to the central street crossing. Hridy dropped something while fleeing.",
		"completed": false
	},
	{
		"id": "stage_3",
		"title": "The West Street Callbox",
		"desc": "Investigate the emergency callbox blinking down the western street for electrical parts.",
		"completed": false
	},
	{
		"id": "stage_4",
		"title": "Commercial Alley Substation",
		"desc": "Locate the alleyway electrical breaker behind the commercial tower and restore street power.",
		"completed": false
	},
	{
		"id": "stage_5",
		"title": "The Abandoned Corner Shop",
		"desc": "Check the powered corner shop down the eastern cross street for the courtyard gate key.",
		"completed": false
	},
	{
		"id": "stage_6",
		"title": "The Courtyard Gate",
		"desc": "Unlock the iron gate leading to the brick apartment courtyard at the eastern block.",
		"completed": false
	},
	{
		"id": "stage_7",
		"title": "Search Heisenberg Hospital",
		"desc": "Enter the 5-story Heisenberg Hospital through the grand entrance. Search the wards and follow the clues to find Hridy on the 5th floor.",
		"completed": false
	},
	{
		"id": "stage_8",
		"title": "Reunion in Hollow Streets",
		"desc": "You found Hridy safe on the 5th floor! Saad and Hridy have reunited in the misty streets.",
		"completed": false
	}
]

var current_objective_index: int = 0

# --- Inventory Data ---
var inventory: Array[Dictionary] = [
	{
		"id": "flashlight",
		"name": "Heavy Flashlight",
		"category": "Tools",
		"icon_symbol": "🔦",
		"desc": "A rugged cast-aluminum field torch. Its intense halogen beam cuts through the dense urban fog. Press [F] during exploration to toggle.",
		"usable": true,
		"examinable": true
	},
	{
		"id": "hridy_letter",
		"name": "Hridy's Letter",
		"category": "Documents",
		"icon_symbol": "✉",
		"desc": "A crumpled, trembling handwritten letter found folded inside Saad's coat pocket. Click 'Read' to open the Journal and read her plea for help.",
		"usable": true,
		"examinable": true
	},
	{
		"id": "health_drink",
		"name": "Herbal Tonic",
		"category": "Supplies",
		"icon_symbol": "🧪",
		"desc": "A sealed antique glass bottle containing an amber herbal extract. Keeps Saad calm and alert in the chilling night air.",
		"usable": true,
		"examinable": true
	},
	{
		"id": "handgun",
		"name": "9mm Service Handgun",
		"category": "Weapons",
		"icon_symbol": "🔫",
		"desc": "Standard issue 9mm semi-automatic pistol. 6-round capacity. Press [1] or [G] to equip/holster, [Left Mouse] to fire, [R] to reload. Saad can walk while shooting.",
		"usable": true,
		"examinable": true
	}
]

# --- Journal Data ---
const HRIDY_LETTER_TEXT: String = """Saad...

If you are reading this, it means you came for me.

I am so sorry I couldn't wait by the car. Something was stalking through the mist—whispering my name from between the alleyways—and I panicked. This town isn't just abandoned, Saad... the streets twist back onto themselves, and shadows move the instant you look away.

When I ran, I dropped my silver locket near the central street crossing. I managed to slip inside the courtyard behind the brick apartments down the eastern street, but the iron gate chained shut behind me. I saw an old brass key resting outside the corner shop before I fled.

Please, Saad... hurry. The cold is getting inside my bones. Don't let them take me into the dark.

Save me, Saad. Please save me.

— Hridy"""

var journal_entries: Array[Dictionary] = [
	{
		"title": "02:15 AM — Arrival at Hollow Streets",
		"date": "Night 1",
		"content": "Arrived at the town outskirts. Heavy fog rolled in without warning. Found Hridy's car empty with the driver's door ajar. Her letter was left behind. I have to find her."
	}
]

var starting_voice_played: bool = false
var is_game_active: bool = false
var is_first_game_start: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen") or (event is InputEventKey and event.pressed and (event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed))):
		toggle_fullscreen()

func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func start_new_game() -> void:
	current_objective_index = 0
	starting_voice_played = false
	is_first_game_start = true
	is_game_active = true
	# Reset objectives completion
	for obj in objectives:
		obj["completed"] = false
	# Reset inventory to initial set
	inventory = [
		{
			"id": "flashlight",
			"name": "Heavy Flashlight",
			"category": "Tools",
			"icon_symbol": "🔦",
			"desc": "A rugged cast-aluminum field torch. Its intense halogen beam cuts through the dense urban fog. Press [F] during exploration to toggle.",
			"usable": true,
			"examinable": true
		},
		{
			"id": "hridy_letter",
			"name": "Hridy's Letter",
			"category": "Documents",
			"icon_symbol": "✉",
			"desc": "A crumpled, trembling handwritten letter found folded inside Saad's coat pocket. Click 'Read' to open the Journal and read her plea for help.",
			"usable": true,
			"examinable": true
		},
		{
			"id": "health_drink",
			"name": "Herbal Tonic",
			"category": "Supplies",
			"icon_symbol": "🧪",
			"desc": "A sealed antique glass bottle containing an amber herbal extract. Keeps Saad calm and alert in the chilling night air.",
			"usable": true,
			"examinable": true
		},
		{
			"id": "handgun",
			"name": "9mm Service Handgun",
			"category": "Weapons",
			"icon_symbol": "🔫",
			"desc": "Standard issue 9mm semi-automatic pistol. 6-round capacity. Press [1] or [G] to equip/holster, [Left Mouse] to fire, [R] to reload. Saad can walk while shooting.",
			"usable": true,
			"examinable": true
		}
	]
	journal_entries = [
		{
			"title": "02:15 AM — Arrival at Hollow Streets",
			"date": "Night 1",
			"content": "Arrived at the town outskirts. Heavy fog rolled in without warning. Found Hridy's car empty with the driver's door ajar. Her letter was left behind. I have to find her."
		}
	]

func get_current_objective() -> Dictionary:
	if current_objective_index < objectives.size():
		return objectives[current_objective_index]
	return {
		"title": "Mystery Solved",
		"desc": "You have located Hridy.",
		"completed": true
	}

func advance_objective(to_index: int, journal_title: String = "", journal_text: String = "") -> void:
	if to_index > current_objective_index and to_index < objectives.size():
		objectives[current_objective_index]["completed"] = true
		current_objective_index = to_index
		var cur := objectives[current_objective_index]
		objective_updated.emit(current_objective_index, cur["title"], cur["desc"])
		
		if journal_title != "" and journal_text != "":
			add_journal_entry(journal_title, journal_text)

func add_journal_entry(title: String, content: String) -> void:
	journal_entries.append({
		"title": title,
		"date": "Night 1",
		"content": content
	})
	journal_updated.emit()

func has_item(item_id: String) -> bool:
	for item in inventory:
		if item["id"] == item_id:
			return true
	return false

func add_item(item: Dictionary) -> void:
	if not has_item(item["id"]):
		inventory.append(item)
		item_added.emit(item)

func remove_item(item_id: String) -> void:
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			inventory.remove_at(i)
			item_removed.emit(item_id)
			break

func play_saad_voice(_voice_res_path: String, subtitle_text: String, duration: float = 4.0) -> void:
	# Saad's spoken voice completely removed - classic SH1 inner thoughts & dialogue text only
	subtitle_requested.emit("Saad", subtitle_text, duration)

var mouse_sensitivity: float = 0.0025
var master_volume: float = 1.0

signal mouse_sensitivity_changed(new_val: float)

func set_mouse_sensitivity(val: float) -> void:
	mouse_sensitivity = val
	mouse_sensitivity_changed.emit(val)

func set_master_volume(linear_vol: float) -> void:
	master_volume = clampf(linear_vol, 0.0, 1.5)
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		if master_volume <= 0.001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))

func trigger_starting_voice() -> void:
	if not starting_voice_played:
		starting_voice_played = true
		subtitle_requested.emit("Saad", "Snow...? In this time of year...?", 3.0)
		get_tree().create_timer(3.2).timeout.connect(func():
			subtitle_requested.emit("Saad", "Hridy! Where are you?! Can you hear me?!", 4.0)
		)

