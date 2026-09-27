extends CharacterBody3D

# Zombie Enemy Controller
# Uses copzombie_l_actisdato model and extracted Mixamo animations (walk, bite, idle).
# Shambles toward Saad, lunges and bites to inflict damage, reacts to gunshots with floating health bar.

enum State { IDLE, WANDER, CHASE, ATTACK, STAGGER, DEAD }

@export var max_health: float = 60.0
@export var walk_speed: float = 1.85
@export var chase_speed: float = 2.6
@export var bite_damage: float = 25.0
@export var detection_range: float = 22.0
@export var bite_range: float = 1.75
@export var bite_cooldown: float = 1.9

var health: float = 60.0
var current_state: State = State.IDLE
var target_player: CharacterBody3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var wander_timer: float = 0.0
var wander_direction: Vector3 = Vector3.ZERO
var groan_timer: float = 3.0
var attack_timer: float = 0.0
var attack_impact_pending: bool = false
var stagger_timer: float = 0.0

@onready var anim_player: AnimationPlayer = $ModelRoot/copzombie_l_actisdato/AnimationPlayer
@onready var health_bar_viewport: SubViewport = $HealthBarRoot/SubViewport
@onready var health_progress_bar: ProgressBar = $HealthBarRoot/SubViewport/ProgressBar
@onready var health_bar_sprite: Sprite3D = $HealthBarRoot/Sprite3D

@onready var sfx_groan: AudioStreamPlayer3D = $SFXGroan
@onready var sfx_bite: AudioStreamPlayer3D = $SFXBite
@onready var sfx_hit: AudioStreamPlayer3D = $SFXHit
@onready var sfx_death: AudioStreamPlayer3D = $SFXDeath
@onready var col_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	health = max_health
	if health_progress_bar:
		health_progress_bar.max_value = max_health
		health_progress_bar.value = health
	
	# Bind custom extracted animation library to the zombie model's AnimationPlayer
	if anim_player:
		var anim_lib: AnimationLibrary = load("res://assets/zombie_animations.tres")
		if anim_lib:
			if anim_player.has_animation_library(""):
				anim_player.remove_animation_library("")
			anim_player.add_animation_library("", anim_lib)
			anim_player.playback_default_blend_time = 0.22
			anim_player.play("idle")
	
	groan_timer = randf_range(2.0, 6.0)
	_pick_new_wander()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		if not is_on_floor():
			velocity.y -= gravity * delta
			move_and_slide()
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	
	# Find player if not tracked
	if not target_player or not is_instance_valid(target_player):
		target_player = get_tree().root.find_child("Player", true, false) as CharacterBody3D
	
	var dist_to_player := INF
	var dir_to_player := Vector3.ZERO
	if target_player and is_instance_valid(target_player):
		var diff := target_player.global_position - global_position
		diff.y = 0.0
		dist_to_player = diff.length()
		if dist_to_player > 0.05:
			dir_to_player = diff.normalized()
	
	# Low, deep guttural growl sound timer (RE2 Remake atmosphere)
	groan_timer -= delta
	if groan_timer <= 0.0:
		groan_timer = randf_range(5.0, 9.5) if current_state == State.CHASE else randf_range(8.0, 15.0)
		if (dist_to_player < detection_range + 6.0) and is_inside_tree() and sfx_groan and not sfx_groan.playing:
			# Deeper and lower pitch (0.60 - 0.76) for ominous, heavy horror presence
			sfx_groan.pitch_scale = randf_range(0.66, 0.76) if current_state == State.CHASE else randf_range(0.60, 0.70)
			sfx_groan.volume_db = -5.0 if current_state == State.CHASE else -6.5
			# Play from randomized position in the 31-second audio file
			var max_len: float = sfx_groan.stream.get_length() if sfx_groan.stream else 30.0
			var start_offset: float = randf_range(0.0, maxf(0.0, max_len - 4.5))
			sfx_groan.play(start_offset)
	
	# Update Health Bar visibility based on proximity and damage
	if health_bar_sprite:
		var show_bar := (health < max_health and health > 0.0) or (dist_to_player < 14.0 and health > 0.0)
		health_bar_sprite.visible = show_bar
	
	# State handling
	match current_state:
		State.STAGGER:
			stagger_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if stagger_timer <= 0.0:
				current_state = State.CHASE
		
		State.ATTACK:
			attack_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			
			# Face player smoothly while attacking
			if dir_to_player != Vector3.ZERO:
				_smooth_look_at(global_position + dir_to_player, 8.0 * delta)
			
			# Deal damage at contact window of the bite animation (~0.4s)
			if attack_impact_pending and attack_timer <= (bite_cooldown - 0.42):
				attack_impact_pending = false
				if dist_to_player <= (bite_range + 0.5):
					_execute_bite()
			
			if attack_timer <= 0.0:
				if dist_to_player <= bite_range:
					_start_bite(dir_to_player)
				else:
					current_state = State.CHASE
		
		State.CHASE:
			if dist_to_player <= bite_range:
				_start_bite(dir_to_player)
			elif dist_to_player <= detection_range:
				_smooth_look_at(global_position + dir_to_player, 6.0 * delta)
				velocity.x = dir_to_player.x * chase_speed
				velocity.z = dir_to_player.z * chase_speed
				if anim_player and anim_player.current_animation != "walk":
					anim_player.play("walk", 0.2, 1.2)
			else:
				current_state = State.WANDER
				_pick_new_wander()
		
		State.WANDER:
			if dist_to_player <= detection_range:
				current_state = State.CHASE
				if anim_player and anim_player.current_animation != "walk":
					anim_player.play("walk", 0.25, 1.0)
			else:
				wander_timer -= delta
				if wander_timer <= 0.0:
					_pick_new_wander()
				
				if wander_direction != Vector3.ZERO:
					_smooth_look_at(global_position + wander_direction, 4.0 * delta)
					velocity.x = wander_direction.x * walk_speed
					velocity.z = wander_direction.z * walk_speed
					if anim_player and anim_player.current_animation != "walk":
						anim_player.play("walk", 0.3, 0.9)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
					velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
					if anim_player and anim_player.current_animation != "idle":
						anim_player.play("idle", 0.3)
		
		State.IDLE:
			if dist_to_player <= detection_range:
				current_state = State.CHASE
			else:
				wander_timer -= delta
				if wander_timer <= 0.0:
					_pick_new_wander()
	
	move_and_slide()

func _pick_new_wander() -> void:
	wander_timer = randf_range(3.0, 7.0)
	if randf() < 0.4:
		# Pause and sniff / idle
		wander_direction = Vector3.ZERO
		current_state = State.IDLE
		if anim_player and anim_player.current_animation != "idle":
			anim_player.play("idle", 0.3)
	else:
		current_state = State.WANDER
		var angle := randf_range(0.0, TAU)
		wander_direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk", 0.25, 0.9)

func _start_bite(dir: Vector3) -> void:
	current_state = State.ATTACK
	attack_timer = bite_cooldown
	attack_impact_pending = true
	velocity.x = 0.0
	velocity.z = 0.0
	
	if anim_player and anim_player.has_animation("bite"):
		anim_player.stop()
		anim_player.play("bite", 0.1, 1.25)

func _execute_bite() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	
	if is_inside_tree() and sfx_bite:
		sfx_bite.pitch_scale = randf_range(0.95, 1.08)
		sfx_bite.play()
	
	if target_player.has_method("take_damage"):
		target_player.take_damage(bite_damage)

func _smooth_look_at(target_pos: Vector3, weight: float) -> void:
	var forward := (target_pos - global_position)
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return
	forward = forward.normalized()
	var target_rot_y := atan2(-forward.x, -forward.z)
	rotation.y = lerp_angle(rotation.y, target_rot_y, weight)

func take_damage(amount: float, hit_pos: Vector3 = Vector3.ZERO, hit_normal: Vector3 = Vector3.UP) -> void:
	if current_state == State.DEAD:
		return
	
	health = maxf(0.0, health - amount)
	
	# Update floating health bar
	if health_progress_bar:
		health_progress_bar.value = health
	if health_bar_sprite:
		health_bar_sprite.visible = true
	
	# Audio impact
	if is_inside_tree() and sfx_hit:
		sfx_hit.pitch_scale = randf_range(0.92, 1.08)
		sfx_hit.play()
	
	# Blood hit particles
	var origin_pos := global_position if is_inside_tree() else Vector3.ZERO
	_spawn_blood_impact(hit_pos if hit_pos != Vector3.ZERO else origin_pos + Vector3(0, 1.3, 0), hit_normal)
	
	if health <= 0.0:
		_die(hit_normal)
	else:
		# Stagger reaction and aggro immediately to player
		current_state = State.STAGGER
		stagger_timer = 0.28
		attack_impact_pending = false
		if hit_normal != Vector3.ZERO:
			velocity.x = -hit_normal.x * 2.2
			velocity.z = -hit_normal.z * 2.2

func _die(hit_normal: Vector3) -> void:
	current_state = State.DEAD
	if health_bar_sprite:
		health_bar_sprite.visible = false
	
	if col_shape:
		col_shape.disabled = true
	
	if sfx_groan and sfx_groan.playing:
		sfx_groan.stop()
	
	if is_inside_tree() and sfx_death:
		sfx_death.pitch_scale = randf_range(0.95, 1.05)
		sfx_death.play()
	
	# Fall backward death animation with Tween collapse
	if anim_player:
		anim_player.pause()
	
	var fall_rot_axis := Vector3.RIGHT
	if hit_normal != Vector3.ZERO:
		fall_rot_axis = Vector3(-hit_normal.z, 0.0, hit_normal.x).normalized()
		if fall_rot_axis.length_squared() < 0.1:
			fall_rot_axis = Vector3.RIGHT
	
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "rotation:x", rotation.x - 1.45, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", position.y - 0.75, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.set_parallel(false)
	
	# Remove or keep corpse in scene after extended duration
	t.tween_interval(45.0)
	t.tween_callback(queue_free)

func _spawn_blood_impact(pos: Vector3, normal: Vector3) -> void:
	if not is_inside_tree() or not get_parent():
		return
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.85, 0.15, 0.15)
	flash.light_energy = 3.5
	flash.omni_range = 2.5
	get_parent().add_child(flash)
	flash.global_position = pos + normal * 0.08
	
	var tw := flash.create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.12)
	tw.tween_callback(flash.queue_free)

