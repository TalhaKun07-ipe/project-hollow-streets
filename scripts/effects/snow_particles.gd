extends Node3D

# Silent Hill 1 Falling Snow & Atmospheric Ash System
# Tracks player's world position with local_coords=false,
# emitting fluttering snow/ash particles across the player's vicinity.

@onready var particles: GPUParticles3D = get_node_or_null("GPUParticles3D")

var player_ref: Node3D = null
var wind_time: float = 0.0

func _ready() -> void:
	if particles:
		particles.local_coords = false
		particles.preprocess = 4.0
		particles.emitting = true

func _process(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().root.find_child("Player", true, false)
		if player_ref == null:
			return
	
	# Anchor emitter directly above player in world space
	# Leaves rotation neutral so flakes fall with world gravity and wind
	global_position = Vector3(
		player_ref.global_position.x,
		player_ref.global_position.y + 7.5,
		player_ref.global_position.z
	)
	global_rotation = Vector3.ZERO
	
	# Subtle atmospheric wind fluctuation
	wind_time += delta * 0.4
	if particles and particles.process_material is ParticleProcessMaterial:
		var mat := particles.process_material as ParticleProcessMaterial
		var wind_x := 0.25 + sin(wind_time * 1.2) * 0.15
		var wind_z := 0.15 + cos(wind_time * 0.9) * 0.12
		mat.direction = Vector3(wind_x, -1.0, wind_z).normalized()
