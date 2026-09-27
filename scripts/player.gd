extends CharacterBody3D

# Kingdom Hearts style third-person movement + Skeletal Animations
# Saad - looking for Hridy
#
# Powered by imported Mixamo skeletal animations (Idle, Walk, Run)
# with procedural turning lean, dynamic footstep scaling, landing impact,
# and physical procedural flashlight system with tactile click audio and micro-flicker.

@export var walk_speed: float = 4.5
@export var run_speed: float = 7.5
@export var crouch_speed: float = 2.2
@export var jump_velocity: float = 6.2
@export var acceleration: float = 14.0
@export var friction: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export var camera_distance: float = 3.3
@export var crouch_camera_distance: float = 2.7

# Dynamic body response
@export var lean_amount: float = 0.08
@export var torch_sway: float = 0.03
@export var landing_squash: float = 0.12

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

const FOOTSTEP_STREAM: AudioStream = preload("res://assets/saad given assets/footsteps sounds.mp3")
const LAND_SOUND: AudioStream = preload("res://assets/audio/footstep_land.wav")
const JUMP_TAKEOFF_SOUND: AudioStream = preload("res://audio/sfx/jump/jump_takeoff.wav")
const FLASHLIGHT_ON: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const FLASHLIGHT_OFF: AudioStream = preload("res://assets/audio/flashlight_click_off.wav")

@onready var col_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var torch_light: SpotLight3D = $Torch/SpotLight3D
@onready var torch_mesh: MeshInstance3D = $Torch/TorchMesh
@onready var saad_model: Node3D = $SaadModel
@onready var torch: Node3D = $Torch
@onready var hand_attachment: BoneAttachment3D = $SaadModel.find_child("RightHandAttachment", true, false)
@onready var anim_player: AnimationPlayer = $SaadModel.find_child("AnimationPlayer", true, false)
@onready var footstep_player: AudioStreamPlayer3D = get_node_or_null("FootstepPlayer")
@onready var landing_player: AudioStreamPlayer3D = get_node_or_null("LandingPlayer")
@onready var flashlight_player: AudioStreamPlayer3D = get_node_or_null("FlashlightPlayer")

var torch_on: bool = true
var current_speed: float = 0.0
var original_model_scale: Vector3 = Vector3(-112.0, 112.0, -112.0)
var was_on_floor: bool = true
var landing_timer: float = 0.0
var current_lean: float = 0.0

# Crouch state & physical parameters
var is_crouch_toggled: bool = false
var is_crouching: bool = false
const STANDING_HEIGHT: float = 2.05
const CROUCH_HEIGHT: float = 1.35
const STANDING_COL_Y: float = 1.025
const CROUCH_COL_Y: float = 0.675
const STANDING_SPRING_Y: float = 1.7
const CROUCH_SPRING_Y: float = 1.25

# Flashlight procedural pose offsets
var torch_raised_pos: Vector3 = Vector3(0.35, 1.25, -0.2)
var torch_lowered_pos: Vector3 = Vector3(0.28, 0.85, 0.05)
var torch_raised_rot: Vector3 = Vector3(0.0, 0.0, 0.0)
var torch_lowered_rot: Vector3 = Vector3(deg_to_rad(-45.0), deg_to_rad(15.0), 0.0)
var torch_tween: Tween = null
var flicker_tween: Tween = null
var inventory_ui: Control = null
var journal_ui: Control = null
var hud_node: Control = null
var game_manager: Node = null
var is_menu_open: bool = false

# Starting cinematic cutscene state
var is_cutscene_active: bool = false
var cutscene_timer: float = 0.0
const CUTSCENE_WALK_SPEED: float = 2.0
const CUTSCENE_TOTAL_TIME: float = 4.6

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if col_shape and col_shape.shape:
		col_shape.shape = col_shape.shape.duplicate()

	if saad_model:
		original_model_scale = saad_model.scale

	# Initialize footstep continuous audio stream
	if footstep_player and is_inside_tree():
		footstep_player.stream = FOOTSTEP_STREAM
		footstep_player.volume_db = -80.0
		footstep_player.pitch_scale = 1.0
		footstep_player.play()
		footstep_player.stream_paused = true

	# Set initial torch state
	if torch:
		torch.position = torch_raised_pos
		torch.rotation = torch_raised_rot
	if torch_light:
		torch_light.visible = true
		torch_light.light_energy = 5.2
	if torch_mesh:
		torch_mesh.visible = true

	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

	# Find UI controllers in scene
	inventory_ui = get_tree().root.find_child("InventoryUI", true, false)
	journal_ui = get_tree().root.find_child("JournalUI", true, false)
	hud_node = get_tree().root.find_child("ObjectiveHUD", true, false)

	if inventory_ui:
		if inventory_ui.has_signal("request_toggle_torch"):
			inventory_ui.request_toggle_torch.connect(func():
				torch_on = not torch_on
				_toggle_flashlight(torch_on)
			)
		if inventory_ui.has_signal("request_open_journal"):
			inventory_ui.request_open_journal.connect(func():
				if journal_ui and journal_ui.has_method("open_journal"):
					journal_ui.open_journal("letter")
			)

	game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.inventory_toggled.connect(func(open: bool):
			is_menu_open = open or (journal_ui != null and journal_ui.get("is_open"))
		)
		game_manager.journal_toggled.connect(func(open: bool):
			is_menu_open = open or (inventory_ui != null and inventory_ui.get("is_open"))
		)

		mouse_sensitivity = game_manager.mouse_sensitivity
		game_manager.mouse_sensitivity_changed.connect(func(v: float):
			mouse_sensitivity = v
		)

		# Trigger opening cinematic cutscene or start normal play
		if game_manager.is_first_game_start:
			game_manager.is_first_game_start = false
			_start_opening_cutscene()
		else:
			is_cutscene_active = false
	else:
		is_cutscene_active = false

func _unhandled_input(event: InputEvent) -> void:
	# Skip cutscene if active
	if is_cutscene_active:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER)):
			_end_opening_cutscene()
			get_viewport().set_input_as_handled()
		return

	# UI shortcut keys
	if event.is_action_pressed("toggle_inventory") or (event is InputEventKey and event.pressed and (event.keycode == KEY_I or event.keycode == KEY_TAB)):
		if inventory_ui and inventory_ui.has_method("open_inventory"):
			if inventory_ui.get("is_open"):
				inventory_ui.close_inventory()
			else:
				if journal_ui and journal_ui.get("is_open"):
					journal_ui.close_journal()
				inventory_ui.open_inventory()
		return

	if event.is_action_pressed("toggle_journal") or (event is InputEventKey and event.pressed and event.keycode == KEY_J):
		if journal_ui and journal_ui.has_method("open_journal"):
			if journal_ui.get("is_open"):
				journal_ui.close_journal()
			else:
				if inventory_ui and inventory_ui.get("is_open"):
					inventory_ui.close_inventory()
				journal_ui.open_journal()
		return

	if is_menu_open or is_cutscene_active:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-55.0), deg_to_rad(30.0))

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
		if pause_menu and pause_menu.has_method("open_pause"):
			pause_menu.open_pause()
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("toggle_torch"):
		torch_on = not torch_on
		_toggle_flashlight(torch_on)

	if event.is_action_pressed("crouch") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_C or event.physical_keycode == KEY_C or event.keycode == KEY_CTRL or event.physical_keycode == KEY_CTRL)):
		_toggle_crouch()

func _toggle_crouch() -> void:
	if is_cutscene_active or is_menu_open:
		return
	if is_crouch_toggled:
		if _is_ceiling_blocked():
			return
		is_crouch_toggled = false
	else:
		is_crouch_toggled = true

func _is_ceiling_blocked() -> bool:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return false
	var head_y := global_position.y + CROUCH_HEIGHT * 0.95
	var target_y := global_position.y + STANDING_HEIGHT + 0.1
	var offsets := [
		Vector3.ZERO,
		Vector3(0.25, 0.0, 0.0),
		Vector3(-0.25, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.25),
		Vector3(0.0, 0.0, -0.25)
	]
	for offset in offsets:
		var from_pos := Vector3(global_position.x + offset.x, head_y, global_position.z + offset.z)
		var to_pos := Vector3(global_position.x + offset.x, target_y, global_position.z + offset.z)
		var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos, 1)
		query.exclude = [get_rid()]
		var result := space_state.intersect_ray(query)
		if not result.is_empty():
			return true
	return false

func _toggle_flashlight(enable: bool) -> void:
	if torch_light == null:
		torch_light = get_node_or_null("Torch/SpotLight3D")
	if torch == null:
		torch = get_node_or_null("Torch")
	if flashlight_player == null:
		flashlight_player = get_node_or_null("FlashlightPlayer")

	if flicker_tween and flicker_tween.is_valid():
		flicker_tween.kill()

	if enable:
		if flashlight_player and is_inside_tree():
			flashlight_player.stream = FLASHLIGHT_ON
			flashlight_player.pitch_scale = randf_range(0.98, 1.02)
			flashlight_player.play()

		# Micro-flicker on light activation
		if torch_light:
			torch_light.visible = true
			torch_light.light_energy = 0.0
			flicker_tween = create_tween()
			flicker_tween.tween_property(torch_light, "light_energy", 3.2, 0.03)
			flicker_tween.tween_property(torch_light, "light_energy", 0.8, 0.02)
			flicker_tween.tween_property(torch_light, "light_energy", 5.2, 0.04)
	else:
		if flashlight_player and is_inside_tree():
			flashlight_player.stream = FLASHLIGHT_OFF
			flashlight_player.pitch_scale = randf_range(0.98, 1.02)
			flashlight_player.play()

		if torch_light:
			torch_light.visible = false

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.1

	var effective_dir := Vector3.ZERO

	if is_cutscene_active:
		cutscene_timer += delta
		if cutscene_timer >= 0.8 and game_manager and not game_manager.starting_voice_played:
			game_manager.trigger_starting_voice()
		var cutscene_forward := -transform.basis.z
		effective_dir = cutscene_forward
		current_speed = CUTSCENE_WALK_SPEED
		velocity.x = cutscene_forward.x * CUTSCENE_WALK_SPEED
		velocity.z = cutscene_forward.z * CUTSCENE_WALK_SPEED

		if cutscene_timer >= CUTSCENE_TOTAL_TIME:
			_end_opening_cutscene()
	else:
		# Evaluate crouch state & obstacle clearance
		if not is_crouch_toggled:
			if is_crouching and _is_ceiling_blocked():
				is_crouching = true
			else:
				is_crouching = false
		else:
			is_crouching = true

		# Sprint or stand-up from sprint
		var sprint_requested := not is_menu_open and Input.is_key_pressed(KEY_SHIFT)
		if sprint_requested and is_crouching and not _is_ceiling_blocked():
			is_crouch_toggled = false
			is_crouching = false

		# Jump or stand up from crouch
		if not is_menu_open and Input.is_action_just_pressed("jump") and is_on_floor():
			if is_crouching:
				if not _is_ceiling_blocked():
					is_crouch_toggled = false
					is_crouching = false
			else:
				velocity.y = jump_velocity
				if anim_player and anim_player.has_animation("jump"):
					anim_player.play("jump", 0.08)
				if landing_player and is_inside_tree():
					landing_player.stream = JUMP_TAKEOFF_SOUND
					landing_player.pitch_scale = randf_range(0.95, 1.05)
					landing_player.volume_db = -2.0
					landing_player.play()

		# Movement direction relative to character rotation
		var input_dir := Vector2.ZERO
		if not is_menu_open:
			input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
		effective_dir = direction

		var target_speed := walk_speed
		if is_crouching:
			target_speed = crouch_speed
		elif sprint_requested:
			target_speed = run_speed

		if direction != Vector3.ZERO:
			current_speed = move_toward(current_speed, target_speed, acceleration * delta)
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			current_speed = move_toward(current_speed, 0.0, friction * delta)
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# Smoothly adjust collision shape height & position
	var target_col_height := CROUCH_HEIGHT if is_crouching else STANDING_HEIGHT
	var target_col_y := CROUCH_COL_Y if is_crouching else STANDING_COL_Y
	if col_shape and col_shape.shape is CapsuleShape3D:
		var cap := col_shape.shape as CapsuleShape3D
		cap.height = lerpf(cap.height, target_col_height, 12.0 * delta)
		col_shape.position.y = lerpf(col_shape.position.y, target_col_y, 12.0 * delta)

	# Smoothly adjust spring arm height and camera distance
	var target_spring_y := CROUCH_SPRING_Y if is_crouching else STANDING_SPRING_Y
	if spring_arm:
		spring_arm.position.y = lerpf(spring_arm.position.y, target_spring_y, 8.0 * delta)

	# Detect landing impact
	var just_landed := is_on_floor() and not was_on_floor
	if just_landed:
		landing_timer = 0.12
		if landing_player and is_inside_tree():
			landing_player.stream = LAND_SOUND
			landing_player.pitch_scale = randf_range(0.95, 1.05)
			landing_player.volume_db = 0.0
			landing_player.play()
	was_on_floor = is_on_floor()

	# Footsteps audio handling (Continuous rhythmic stream from saad given assets)
	if footstep_player:
		var is_moving_on_ground := is_on_floor() and current_speed > 0.4
		if is_moving_on_ground:
			if footstep_player.stream_paused:
				footstep_player.stream_paused = false
			if is_crouching:
				# Stealthy, muffled, slower-paced crouch steps
				var crouch_ratio := clampf(current_speed / crouch_speed, 0.0, 1.0)
				var target_pitch := lerpf(0.82, 0.96, crouch_ratio)
				footstep_player.pitch_scale = lerpf(footstep_player.pitch_scale, target_pitch, 8.0 * delta)
				footstep_player.volume_db = lerpf(footstep_player.volume_db, -8.0, 10.0 * delta)
			else:
				# Modulate pitch by movement speed (walk: ~1.0, run: ~1.35)
				var speed_ratio := clampf((current_speed - walk_speed * 0.5) / (run_speed - walk_speed * 0.5), 0.0, 1.0)
				var target_pitch := lerpf(0.95, 1.35, speed_ratio)
				footstep_player.pitch_scale = lerpf(footstep_player.pitch_scale, target_pitch, 8.0 * delta)
				footstep_player.volume_db = lerpf(footstep_player.volume_db, -2.0, 12.0 * delta)
		else:
			footstep_player.volume_db = lerpf(footstep_player.volume_db, -80.0, 14.0 * delta)
			if footstep_player.volume_db < -50.0 and not footstep_player.stream_paused:
				footstep_player.stream_paused = true

	move_and_slide()

	# Anchor torch directly to Saad's right hand bone
	if torch and torch.is_inside_tree():
		if hand_attachment:
			torch.global_position = hand_attachment.global_position
		if torch_on:
			var aim_target := torch.global_position - transform.basis.z * 15.0 + Vector3(0.0, -1.0, 0.0)
			torch.look_at(aim_target, Vector3.UP)
		else:
			var rest_target := torch.global_position + Vector3(0.0, -1.0, 0.0) - transform.basis.z * 0.2
			var fwd := (rest_target - torch.global_position).normalized()
			var up_vec := -transform.basis.z if abs(fwd.dot(Vector3.UP)) > 0.9 else Vector3.UP
			torch.look_at(rest_target, up_vec)

	# Safety fallback if falling below world
	if global_position.y < -15.0:
		global_position = Vector3(0.0, 2.5, 0.0)
		velocity = Vector3.ZERO

	_update_animation(delta, effective_dir)
	if spring_arm and not is_cutscene_active:
		var target_cam_dist := crouch_camera_distance if is_crouching else camera_distance
		spring_arm.spring_length = lerpf(spring_arm.spring_length, target_cam_dist, 8.0 * delta)

func _update_animation(delta: float, move_dir: Vector3) -> void:
	# --- Skeletal Animation Playback ---
	if anim_player:
		if is_crouching:
			if current_speed > 0.2:
				if anim_player.current_animation != "crouch_walk":
					anim_player.play("crouch_walk", 0.2)
				anim_player.speed_scale = clampf(current_speed / crouch_speed, 0.7, 1.4)
			else:
				if anim_player.current_animation != "crouch_idle" and anim_player.current_animation != "crouch":
					anim_player.play("crouch_idle", 0.25)
				anim_player.speed_scale = 1.0
		elif not is_on_floor():
			if anim_player.has_animation("jump"):
				if anim_player.current_animation != "jump" and anim_player.current_animation != "jumping":
					anim_player.play("jump", 0.15)
				anim_player.speed_scale = 1.0
			elif anim_player.current_animation != "":
				anim_player.speed_scale = 0.5
		elif current_speed > 5.0:
			if anim_player.current_animation != "run":
				anim_player.play("run", 0.2)
			anim_player.speed_scale = clampf(current_speed / run_speed, 0.8, 1.3)
		elif current_speed > 0.2:
			if anim_player.current_animation == "idle":
				if anim_player.has_animation("start_walking"):
					anim_player.play("start_walking", 0.15)
					anim_player.speed_scale = clampf(current_speed / walk_speed, 0.9, 1.4)
				else:
					anim_player.play("walk", 0.2)
					anim_player.speed_scale = clampf(current_speed / walk_speed, 0.7, 1.3)
			elif anim_player.current_animation == "start_walking" or anim_player.current_animation == "walk_start":
				if anim_player.current_animation_position > 0.6 or not anim_player.is_playing():
					anim_player.play("walk", 0.25)
				anim_player.speed_scale = clampf(current_speed / walk_speed, 0.8, 1.3)
			elif anim_player.current_animation != "walk":
				anim_player.play("walk", 0.2)
				anim_player.speed_scale = clampf(current_speed / walk_speed, 0.7, 1.3)
			else:
				anim_player.speed_scale = clampf(current_speed / walk_speed, 0.7, 1.3)
		else:
			if anim_player.current_animation != "idle":
				anim_player.play("idle", 0.25)
			anim_player.speed_scale = 1.0

	# --- Turn Banking / Leaning ---
	var target_lean := 0.0
	var speed_factor := clampf(current_speed / run_speed, 0.0, 1.0)
	if move_dir != Vector3.ZERO and is_on_floor():
		var local_dir := transform.basis.inverse() * move_dir
		var crouch_mult := 0.6 if is_crouching else 1.0
		target_lean = clampf(-local_dir.x, -1.0, 1.0) * lean_amount * clampf(speed_factor + 0.3, 0.0, 1.0) * crouch_mult
	current_lean = lerpf(current_lean, target_lean, delta * 8.0)

	if saad_model:
		saad_model.rotation.z = -current_lean

	# --- Landing squash & stretch recovery ---
	if landing_timer > 0.0:
		landing_timer -= delta
		var t := clampf(landing_timer / 0.12, 0.0, 1.0)
		var squash := sin(t * PI) * landing_squash
		if saad_model:
			saad_model.scale = original_model_scale * Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5)
	elif saad_model and saad_model.scale != original_model_scale:
		saad_model.scale = saad_model.scale.lerp(original_model_scale, delta * 10.0)

func _start_opening_cutscene() -> void:
	is_cutscene_active = true
	cutscene_timer = 0.0
	spring_arm.spring_length = 3.6
	if not hud_node:
		hud_node = get_tree().root.find_child("ObjectiveHUD", true, false)
	if hud_node and hud_node.has_method("show_cinematic_bars"):
		hud_node.show_cinematic_bars(0.8)

func _end_opening_cutscene() -> void:
	if not is_cutscene_active:
		return
	is_cutscene_active = false
	if game_manager and not game_manager.starting_voice_played:
		game_manager.trigger_starting_voice()
	if not hud_node:
		hud_node = get_tree().root.find_child("ObjectiveHUD", true, false)
	if hud_node and hud_node.has_method("fade_out_cinematic_bars"):
		hud_node.fade_out_cinematic_bars(1.2)
	var t := create_tween()
	t.tween_property(spring_arm, "spring_length", camera_distance, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
