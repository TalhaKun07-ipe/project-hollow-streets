extends CharacterBody3D

# Kingdom Hearts style third-person movement + Skeletal Animations
# Saad - looking for Hridy
#
# Powered by imported Mixamo skeletal animations (Idle, Walk, Run)
# with procedural turning lean, dynamic footstep scaling, and landing impact.

@export var walk_speed: float = 4.5
@export var run_speed: float = 7.5
@export var jump_velocity: float = 6.2
@export var acceleration: float = 14.0
@export var friction: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export var camera_distance: float = 4.2

# Dynamic body response
@export var lean_amount: float = 0.08
@export var torch_sway: float = 0.03
@export var landing_squash: float = 0.12

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var torch_light: SpotLight3D = $Torch/SpotLight3D
@onready var torch_mesh: MeshInstance3D = $Torch/TorchMesh
@onready var saad_model: Node3D = $SaadModel
@onready var torch: Node3D = $Torch
@onready var anim_player: AnimationPlayer = $SaadModel.find_child("AnimationPlayer", true, false)

var torch_on: bool = true
var current_speed: float = 0.0
var original_model_scale: Vector3 = Vector3(-100.0, 100.0, -100.0)
var original_torch_pos: Vector3 = Vector3.ZERO
var was_on_floor: bool = true
var landing_timer: float = 0.0
var current_lean: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if torch_light:
		torch_light.visible = true
	if torch_mesh:
		torch_mesh.visible = true

	if saad_model:
		original_model_scale = saad_model.scale
	if torch:
		original_torch_pos = torch.position

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
		if torch_light:
			torch_light.visible = torch_on
		if torch_mesh:
			torch_mesh.visible = torch_on

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
	was_on_floor = is_on_floor()

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
			# Keep current pose or slow it down during airtime
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

	# --- Torch sway follow ---
	if torch:
		var sway_offset := sin(Time.get_ticks_msec() * 0.008) * torch_sway * speed_factor
		torch.position.x = lerpf(torch.position.x, original_torch_pos.x + sway_offset, delta * 6.0)

	# --- Landing squash & stretch recovery ---
	if landing_timer > 0.0:
		landing_timer -= delta
		var t := clampf(landing_timer / 0.12, 0.0, 1.0)
		var squash := sin(t * PI) * landing_squash
		if saad_model:
			saad_model.scale = original_model_scale * Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5)
	elif saad_model and saad_model.scale != original_model_scale:
		saad_model.scale = saad_model.scale.lerp(original_model_scale, delta * 10.0)
