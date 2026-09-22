extends CharacterBody3D

# Kingdom Hearts style third-person movement + Skeletal Animations
# Saad - looking for Hridy
#
# Powered by imported Mixamo skeletal animations (Idle, Walk, Run)
# with procedural turning lean, dynamic footstep scaling, landing impact,
# and physical procedural flashlight system with tactile click audio and micro-flicker.

@export var walk_speed: float = 4.5
@export var run_speed: float = 7.5
@export var jump_velocity: float = 6.2
@export var acceleration: float = 14.0
@export var friction: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export var camera_distance: float = 3.3

# Dynamic body response
@export var lean_amount: float = 0.08
@export var torch_sway: float = 0.03
@export var landing_squash: float = 0.12

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

const FOOTSTEP_STREAM: AudioStream = preload("res://assets/saad given assets/footsteps sounds.mp3")
const LAND_SOUND: AudioStream = preload("res://assets/audio/footstep_land.wav")
const FLASHLIGHT_ON: AudioStream = preload("res://assets/audio/flashlight_click_on.wav")
const FLASHLIGHT_OFF: AudioStream = preload("res://assets/audio/flashlight_click_off.wav")

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var torch_light: SpotLight3D = $Torch/SpotLight3D
@onready var torch_mesh: MeshInstance3D = $Torch/TorchMesh
@onready var saad_model: Node3D = $SaadModel
@onready var torch: Node3D = $Torch
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

# Flashlight procedural pose offsets
var torch_raised_pos: Vector3 = Vector3(0.35, 1.25, -0.2)
var torch_lowered_pos: Vector3 = Vector3(0.28, 0.85, 0.05)
var torch_raised_rot: Vector3 = Vector3(0.0, 0.0, 0.0)
var torch_lowered_rot: Vector3 = Vector3(deg_to_rad(-45.0), deg_to_rad(15.0), 0.0)
var torch_tween: Tween = null
var flicker_tween: Tween = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-55.0), deg_to_rad(30.0))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("toggle_torch"):
		torch_on = not torch_on
		_toggle_flashlight(torch_on)

func _toggle_flashlight(enable: bool) -> void:
	if torch_light == null:
		torch_light = get_node_or_null("Torch/SpotLight3D")
	if torch == null:
		torch = get_node_or_null("Torch")
	if flashlight_player == null:
		flashlight_player = get_node_or_null("FlashlightPlayer")

	if torch_tween and torch_tween.is_valid():
		torch_tween.kill()
	if flicker_tween and flicker_tween.is_valid():
		flicker_tween.kill()

	torch_tween = create_tween().set_parallel(true)

	if enable:
		if flashlight_player and is_inside_tree():
			flashlight_player.stream = FLASHLIGHT_ON
			flashlight_player.pitch_scale = randf_range(0.98, 1.02)
			flashlight_player.play()

		# Smoothly raise flashlight to aiming position
		if torch:
			torch_tween.tween_property(torch, "position", torch_raised_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			torch_tween.tween_property(torch, "rotation", torch_raised_rot, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Micro-flicker on light activation (bulb warm-up)
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

		# Lower flashlight toward hip resting pose (stays visible on player body)
		if torch:
			torch_tween.tween_property(torch, "position", torch_lowered_pos, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			torch_tween.tween_property(torch, "rotation", torch_lowered_rot, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.1

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement direction relative to character rotation
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_speed := run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	if direction != Vector3.ZERO:
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		current_speed = move_toward(current_speed, 0.0, friction * delta)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

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
		var is_moving_on_ground := is_on_floor() and current_speed > 0.6
		if is_moving_on_ground:
			if footstep_player.stream_paused:
				footstep_player.stream_paused = false
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

	# Safety fallback if falling below world
	if global_position.y < -15.0:
		global_position = Vector3(0.0, 2.5, 0.0)
		velocity = Vector3.ZERO

	_update_animation(delta, direction)
	spring_arm.spring_length = camera_distance

func _update_animation(delta: float, move_dir: Vector3) -> void:
	# --- Skeletal Animation Playback ---
	if anim_player:
		if not is_on_floor():
			anim_player.speed_scale = 0.5
		elif current_speed > 5.0:
			if anim_player.current_animation != "run":
				anim_player.play("run", 0.2)
			anim_player.speed_scale = clampf(current_speed / run_speed, 0.8, 1.3)
		elif current_speed > 0.2:
			if anim_player.current_animation != "walk":
				anim_player.play("walk", 0.2)
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
		target_lean = clampf(-local_dir.x, -1.0, 1.0) * lean_amount * clampf(speed_factor + 0.3, 0.0, 1.0)
	current_lean = lerpf(current_lean, target_lean, delta * 8.0)

	if saad_model:
		saad_model.rotation.z = -current_lean

	# --- Torch sway follow when raised ---
	if torch and torch_on and (torch_tween == null or not torch_tween.is_valid()):
		var sway_offset := sin(Time.get_ticks_msec() * 0.008) * torch_sway * speed_factor
		torch.position.x = lerpf(torch.position.x, torch_raised_pos.x + sway_offset, delta * 6.0)

	# --- Landing squash & stretch recovery ---
	if landing_timer > 0.0:
		landing_timer -= delta
		var t := clampf(landing_timer / 0.12, 0.0, 1.0)
		var squash := sin(t * PI) * landing_squash
		if saad_model:
			saad_model.scale = original_model_scale * Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5)
	elif saad_model and saad_model.scale != original_model_scale:
		saad_model.scale = saad_model.scale.lerp(original_model_scale, delta * 10.0)
