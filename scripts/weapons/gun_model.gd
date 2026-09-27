extends Node3D

# Gun Model Controller
# Handles muzzle flash visibility and lighting pulse upon firing.

@onready var flash_mesh: MeshInstance3D = $Muzzle/FlashMesh
@onready var muzzle_light: OmniLight3D = $Muzzle/MuzzleLight

var flash_tween: Tween = null

func flash_muzzle() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	if flash_mesh:
		flash_mesh.visible = true
		flash_mesh.scale = Vector3.ONE * randf_range(0.8, 1.4)
	if muzzle_light:
		muzzle_light.visible = true
		muzzle_light.light_energy = randf_range(6.0, 9.0)
	
	flash_tween = create_tween()
	flash_tween.tween_interval(0.04)
	flash_tween.tween_callback(func():
		if flash_mesh:
			flash_mesh.visible = false
		if muzzle_light:
			muzzle_light.visible = false
	)
