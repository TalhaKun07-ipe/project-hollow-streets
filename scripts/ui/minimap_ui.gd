extends Control

# Survival Horror Street Minimap & Objective Beacon Radar
# Renders a weathered street navigation map showing Saad's position,
# orientation, and dynamic objective destination markers.

@export var map_range_meters: float = 90.0 # visible radius in world meters
@export var zoom_scale: float = 1.0

@onready var map_canvas: Control = $MapFrame/MapCanvas
@onready var player_marker: Control = $MapFrame/MapCanvas/PlayerMarker
@onready var objective_marker: Control = $MapFrame/MapCanvas/ObjectiveMarker
@onready var beacon_ring: Control = $MapFrame/MapCanvas/ObjectiveMarker/PulseRing
@onready var target_label: Label = $InfoCard/VBox/TargetLabel
@onready var distance_label: Label = $InfoCard/VBox/DistanceLabel
@onready var compass_needle: Control = $MapFrame/Compass/Needle

var player_ref: Node3D = null
var pulse_time: float = 0.0

# Objective world targets corresponding to stages
var objective_positions: Dictionary = {
	0: {"pos": Vector2(0.0, -95.0), "name": "Abandoned Car (North)"},
	1: {"pos": Vector2(0.0, -95.0), "name": "Hridy's Stalled Sedan"},
	2: {"pos": Vector2(2.0, -6.0), "name": "Dropped Silver Locket"},
	3: {"pos": Vector2(-65.0, -8.0), "name": "West Emergency Callbox"},
	4: {"pos": Vector2(-22.0, -65.0), "name": "Alley Power Breaker"},
	5: {"pos": Vector2(18.5, 13.5), "name": "East Corner Shop (Key)"},
	6: {"pos": Vector2(28.0, 30.0), "name": "Apartment Courtyard Gate"},
	7: {"pos": Vector2(34.0, 52.0), "name": "Grand Hospital (Floor 5)"},
	8: {"pos": Vector2(34.0, 52.0), "name": "Hridy Rescued!"}
}

# Dynamic item markers (weapons, ammo pickups, etc.)
var item_markers: Dictionary = {}

func register_item_marker(id: String, world_pos: Vector3, label: String, color: Color = Color(1.0, 0.85, 0.2)) -> void:
	item_markers[id] = {
		"pos": Vector2(world_pos.x, world_pos.z),
		"label": label,
		"color": color
	}
	if map_canvas:
		map_canvas.queue_redraw()

func unregister_item_marker(id: String) -> void:
	if item_markers.has(id):
		item_markers.erase(id)
		if map_canvas:
			map_canvas.queue_redraw()

func _ready() -> void:
	map_canvas.draw.connect(_on_map_draw)

func _process(delta: float) -> void:
	if not visible:
		return
	
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().root.find_child("Player", true, false)
	
	pulse_time += delta * 3.0
	var ring_scale := 1.0 + (fmod(pulse_time, 2.0) * 0.8)
	var ring_alpha := 1.0 - (fmod(pulse_time, 2.0) * 0.5)
	if beacon_ring:
		beacon_ring.scale = Vector2(ring_scale, ring_scale)
		beacon_ring.modulate.a = ring_alpha
	
	map_canvas.queue_redraw()
	_update_markers()

func _update_markers() -> void:
	if not player_ref or not map_canvas:
		return
	
	var canvas_size: Vector2 = map_canvas.size
	var center: Vector2 = canvas_size * 0.5
	var px: float = player_ref.global_position.x
	var pz: float = player_ref.global_position.z
	var rot_y: float = player_ref.rotation.y
	
	# Rotate compass
	if compass_needle:
		compass_needle.rotation = -rot_y
	
	# Current stage destination
	var stage: int = GameManager.current_objective_index
	var target_data: Dictionary = objective_positions.get(stage, {"pos": Vector2.ZERO, "name": "Area"})
	var target_pos_world: Vector2 = target_data["pos"]
	
	# Distance
	var diff := target_pos_world - Vector2(px, pz)
	var dist_m := diff.length()
	
	# Calculate compass heading string
	var angle := -atan2(diff.x, -diff.y) # angle from north
	var dir_str := _angle_to_direction(angle)
	
	target_label.text = "TARGET: " + target_data["name"].to_upper()
	distance_label.text = "DISTANCE: " + str(int(dist_m)) + "m " + dir_str
	
	# Center map around player or show local radar
	# Player is always centered on radar
	player_marker.position = center
	player_marker.rotation = -rot_y
	
	# Position objective relative to player
	var scale_factor := (canvas_size.x * 0.45) / map_range_meters
	var rel_x := diff.x * scale_factor
	var rel_y := diff.y * scale_factor
	
	# Clamp marker inside circular frame
	var rel_vec := Vector2(rel_x, rel_y)
	var max_radius := canvas_size.x * 0.44
	if rel_vec.length() > max_radius:
		rel_vec = rel_vec.normalized() * max_radius
	
	objective_marker.position = center + rel_vec

func _angle_to_direction(rad: float) -> String:
	var deg := wrapf(rad_to_deg(rad), 0.0, 360.0)
	if deg >= 337.5 or deg < 22.5:
		return "[N]"
	elif deg >= 22.5 and deg < 67.5:
		return "[NE]"
	elif deg >= 67.5 and deg < 112.5:
		return "[E]"
	elif deg >= 112.5 and deg < 157.5:
		return "[SE]"
	elif deg >= 157.5 and deg < 202.5:
		return "[S]"
	elif deg >= 202.5 and deg < 247.5:
		return "[SW]"
	elif deg >= 247.5 and deg < 292.5:
		return "[W]"
	else:
		return "[NW]"

func _on_map_draw() -> void:
	var size := map_canvas.size
	var center := size * 0.5
	var radius := size.x * 0.45
	
	# Draw radar background circle
	map_canvas.draw_circle(center, radius, Color(0.04, 0.04, 0.05, 0.88))
	map_canvas.draw_arc(center, radius, 0, TAU, 32, Color(0.55, 0.25, 0.2, 0.7), 2.0)
	map_canvas.draw_arc(center, radius * 0.5, 0, TAU, 24, Color(0.35, 0.3, 0.3, 0.35), 1.0)
	
	if not player_ref:
		return
	
	var px: float = player_ref.global_position.x
	var pz: float = player_ref.global_position.z
	var scale_factor := radius / map_range_meters
	
	# Draw Main Avenue (NS, X=0, width 14m)
	var road_x := center.x + (-px * scale_factor)
	var road_w := 14.0 * scale_factor
	var road_rect_ns := Rect2(road_x - road_w * 0.5, 0, road_w, size.y)
	map_canvas.draw_rect(road_rect_ns, Color(0.18, 0.18, 0.22, 0.35))
	
	# Draw Cross Street (EW, Z=0, width 12m)
	var road_y := center.y + (-pz * scale_factor)
	var road_h := 12.0 * scale_factor
	var road_rect_ew := Rect2(0, road_y - road_h * 0.5, size.x, road_h)
	map_canvas.draw_rect(road_rect_ew, Color(0.18, 0.18, 0.22, 0.35))
	
	# Draw building blocks
	var bld_color := Color(0.35, 0.25, 0.22, 0.35)
	# Corner shop at (19, 18)
	var cs_pos := center + Vector2(19.0 - px, 18.0 - pz) * scale_factor
	map_canvas.draw_rect(Rect2(cs_pos.x - 7 * scale_factor, cs_pos.y - 6 * scale_factor, 14 * scale_factor, 12 * scale_factor), bld_color)
	# Apartments at (38, 18) and (19, 42)
	var ap1_pos := center + Vector2(38.0 - px, 18.0 - pz) * scale_factor
	map_canvas.draw_rect(Rect2(ap1_pos.x - 8 * scale_factor, ap1_pos.y - 6 * scale_factor, 16 * scale_factor, 12 * scale_factor), bld_color)
	var ap2_pos := center + Vector2(19.0 - px, 42.0 - pz) * scale_factor
	map_canvas.draw_rect(Rect2(ap2_pos.x - 6 * scale_factor, ap2_pos.y - 8 * scale_factor, 12 * scale_factor, 16 * scale_factor), bld_color)

	# Grand Hospital building at (34, 52), size 26m x 22m
	var hosp_pos := center + Vector2(34.0 - px, 52.0 - pz) * scale_factor
	var hosp_rect := Rect2(hosp_pos.x - 13.0 * scale_factor, hosp_pos.y - 11.0 * scale_factor, 26.0 * scale_factor, 22.0 * scale_factor)
	map_canvas.draw_rect(hosp_rect, Color(0.25, 0.35, 0.45, 0.45))
	map_canvas.draw_rect(hosp_rect, Color(0.4, 0.7, 0.9, 0.6), false, 1.5)
	
	# Draw dynamic item markers (guns, ammo pickups, etc.)
	var font = ThemeDB.fallback_font
	for m_id in item_markers:
		var item: Dictionary = item_markers[m_id]
		var item_pos: Vector2 = item["pos"]
		var rel_pos := (item_pos - Vector2(px, pz)) * scale_factor
		var marker_scr := center + rel_pos
		var dist_to_center := (marker_scr - center).length()
		var clamped := false
		if dist_to_center > radius - 6.0:
			marker_scr = center + (marker_scr - center).normalized() * (radius - 6.0)
			clamped = true
		
		var col: Color = item.get("color", Color(1.0, 0.85, 0.2))
		var is_gun: bool = "gun" in str(item.get("label", "")).to_lower()
		
		# Draw pulsing outer ring
		var pulse := (sin(pulse_time * 2.0) * 0.5 + 0.5)
		var marker_radius: float = 6.0 if is_gun else 4.0
		map_canvas.draw_circle(marker_scr, marker_radius + (pulse * 3.0), Color(col.r, col.g, col.b, 0.35 * (1.0 - pulse * 0.5)))
		# Draw marker core
		map_canvas.draw_circle(marker_scr, marker_radius, col)
		map_canvas.draw_arc(marker_scr, marker_radius, 0, TAU, 12, Color.WHITE, 1.2)
		
		# Draw label if unclamped
		if not clamped and dist_to_center < radius * 0.85 and font:
			var lbl: String = item.get("label", "")
			map_canvas.draw_string(font, marker_scr + Vector2(-30, -8), lbl, HORIZONTAL_ALIGNMENT_CENTER, 60, 9, Color(1, 1, 1, 0.9))

	# Compass crosshairs
	map_canvas.draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), Color(0.4, 0.35, 0.35, 0.25), 1.0)
	map_canvas.draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), Color(0.4, 0.35, 0.35, 0.25), 1.0)
