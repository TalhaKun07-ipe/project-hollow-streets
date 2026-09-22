# Technical Architecture & Systems Specification

*Project Hollow Streets v2.0 (Saad & Hridy)*  
*Engine: Godot 4.7.2 Forward+ Rendering Pipeline*

---

## 1. Engine & Project Configuration

The project is configured via [`project.godot`](file:///c:/Users/USER/Desktop/saad%20game/project.godot).

### Key Parameters:
* **Engine Version:** Godot 4.7 / 4.3 Forward+ (Config features: `["4.3", "Forward Plus"]`)
* **Renderer:** Forward+ (Desktop high-fidelity clustering renderer supporting clustered lights, volumetric fog, and compute shaders)
* **Main Scene:** `res://scenes/main.tscn`
* **Viewport Size:** $1280 \times 720$
* **Stretch Mode:** `canvas_items` (ensures UI elements scale cleanly to higher display resolutions)
* **Anti-Aliasing:** 3D MSAA set to `2x`
* **Default Clear Color:** `Color(0.05, 0.05, 0.08, 1)` (deep midnight blue/charcoal)

---

## 2. Input Mapping System

Defined in `project.godot`:

| Action Name | Physical Key | Scancode | Note |
| :--- | :--- | :--- | :--- |
| `move_forward` | `W` | 87 | Player forward movement |
| `move_back` | `S` | 83 | Player backward movement |
| `move_left` | `A` | 65 | Player strafe left |
| `move_right` | `D` | 68 | Player strafe right |
| `jump` | `Space` | 32 | Jump upward |
| `toggle_torch` | `F` | 70 | Flashlight on/off |
| `ui_cancel` | `Esc` | Built-in | Mouse cursor capture toggle |

---

## 3. Physics & Collision Layers

Configured 3D Physics Layers:
* **Layer 1 (`world`):** Static world collision geometry (Ground, roads, buildings, boundary walls, obstacles).
* **Layer 2 (`player`):** Player character collider (`CharacterBody3D`).
* *(Planned)* **Layer 3 (`interactable`):** Notes, items, clues, doors.
* *(Planned)* **Layer 4 (`npc`):** Hridy / other characters.

---

## 4. Scene Architecture & Hierarchies

### A. Player Scene (`res://scenes/player.tscn`)

The player is constructed as a self-contained `CharacterBody3D` prefab:

```text
Player (CharacterBody3D) [Collision Layer: 2 (player), floor_max_angle: 0.8 rad (~45°)]
 ├── CollisionShape3D (CapsuleShape3D, radius: 0.45m, height: 2.05m, y-offset: 1.025m)
 ├── SaadModel (Instance of res://scenes/saad_model_animated.tscn, scale: (-112, 112, -112))
 │    ├── Skeleton3D (65-bone Mixamo humanoid rig)
 │    │    ├── avaturn_body (MeshInstance3D, mat_saad_body.tres)
 │    │    ├── avaturn_hair_0 (MeshInstance3D, mat_saad_hair.tres)
 │    │    ├── avaturn_hair_1 (MeshInstance3D, mat_saad_hair.tres)
 │    │    ├── avaturn_shoes_0 (MeshInstance3D, mat_saad_shoes.tres)
 │    │    └── avaturn_look_0 (MeshInstance3D, mat_saad_clothes.tres)
 │    └── AnimationPlayer (loaded with res://assets/saad_animations.tres)
 │         ├── 'idle': 8.33s breathing/posture loop (from Idle.fbx)
 │         ├── 'walk': 1.033s walking cycle (from Walking.fbx)
 │         └── 'run': 1.066s sprinting cycle (from Running.fbx)
 ├── SpringArm3D (Camera boom: length: 3.3m, margin: 0.25m, y-offset: 1.7m)
 │    └── Camera3D (current: true, fov: 70.0°)
 ├── Torch (Node3D, procedural position & rotation via Tween)
 │    ├── TorchMesh (MeshInstance3D: CylinderMesh metallic flashlight handle)
 │    └── SpotLight3D (range: 75.0m, energy: 5.2, color: (1, 0.88, 0.65), shadows: true)
 ├── FootstepPlayer (AudioStreamPlayer3D: footsteps sounds.mp3, continuous speed-pitch modulated stream)
 ├── LandingPlayer (AudioStreamPlayer3D: footstep_land.wav, touchdown impact)
 └── FlashlightPlayer (AudioStreamPlayer3D: flashlight_click_on.wav & click_off.wav)
```

### B. Main World Scene (`res://scenes/main.tscn`)

The main game environment representing the mist-draped urban district:

```text
Main (Node3D)
 ├── WorldEnvironment
 │    ├── ProceduralSkyMaterial (midnight blue sky dome)
 │    ├── Volumetric Fog (density: 0.065, albedo: (0.55, 0.65, 0.78), ambient_inject: 0.55)
 │    └── Distance Depth Fog (density: 0.022, light_color: (0.25, 0.32, 0.45))
 ├── DirectionalLight3D (Moonlight: angle (0.866, -0.353, 0.353), shadows: 180m distance)
 ├── Ground (StaticBody3D: 300m x 300m plane with rocky terrain PBR material)
 ├── RoadNetwork (Asphalt avenue 14m wide, cross street 12m wide, 4 zebra crosswalks)
 ├── Sidewalks (Concrete walkways, 4m wide, 0.18m raised curbs)
 ├── StreetLamps (36 instances of res://scenes/props/street_lamp.tscn)
 ├── Buildings (24 modular building instances across 4 blocks):
 │    ├── BrickApartments (Instances of res://scenes/buildings/building_brick_apartment.tscn)
 │    ├── CommercialTowers (Instances of res://scenes/buildings/building_commercial_tower.tscn)
 │    └── CornerShops (Instances of res://scenes/buildings/building_corner_shop.tscn)
 ├── BoundaryWalls (4 StaticBody3D collision planes at X = ±145m, Z = ±145m)
 ├── BackgroundMusic (AudioStreamPlayer: background_music.mp3 via scripts/background_music.gd)
 └── Player (Instance of res://scenes/player.tscn, spawn at (0, 0.1, 0))
```

---

## 5. Script Breakdown: `player.gd`

File: [`scripts/player.gd`](file:///c:/Users/USER/Desktop/saad%20game/scripts/player.gd)  
Extends: `CharacterBody3D`

### 5.1 Player State & Configuration Properties

* **Locomotion:**
  * `walk_speed: float = 4.5` m/s
  * `run_speed: float = 7.5` m/s (activated while holding `Shift`)
  * `jump_velocity: float = 6.2` m/s
  * `acceleration: float = 14.0` m/s²
  * `friction: float = 12.0` m/s²
  * `gravity`: Inherited from Godot project settings (`physics/3d/default_gravity`, approx 9.8 m/s²).
* **Camera & Controls:**
  * `mouse_sensitivity: float = 0.0025`
  * `camera_distance: float = 3.3` meters
  * `Camera3D.fov = 70.0` degrees
* **Dynamic Body Juice:**
  * `lean_amount: float = 0.08` (procedural turn banking into turns)
  * `landing_squash: float = 0.12` (touchdown vertical compression recovery)
  * `torch_sway: float = 0.03` (subtle lateral torch bobbing when walking)

### 5.2 Flashlight Procedural Animation & Audio

When the user presses `toggle_torch` (`F`):
1. **Toggle ON:**
   * Plays `assets/audio/flashlight_click_on.wav` on `FlashlightPlayer`.
   * Tweens torch position smoothly from hip resting pose `(0.28, 0.85, 0.05)` to raised aim pose `(0.35, 1.25, -0.2)` in $0.22\text{s}$.
   * Triggers micro-flicker warm-up on `SpotLight3D.light_energy` ($0 \rightarrow 3.2 \rightarrow 0.8 \rightarrow 5.2$) in $0.09\text{s}$.
2. **Toggle OFF:**
   * Plays `assets/audio/flashlight_click_off.wav`.
   * Cuts light beam (`visible = false`).
   * Tweens torch smoothly to hip resting pose in $0.26\text{s}$. The physical torch mesh remains visible clipped to Saad's hip.

### 5.3 Audio Engineering: Speed-Adaptive Footsteps

* Loads `res://assets/saad given assets/footsteps sounds.mp3` as a continuous looping stream.
* When moving on ground (`is_on_floor() and current_speed > 0.6`):
  * Fades volume up to $-2.0\text{ dB}$.
  * Modulates pitch dynamically: `pitch_scale = lerpf(0.95, 1.35, speed_ratio)`.
* When stopped or jumping:
  * Smoothly fades volume to $-80\text{ dB}$ and pauses stream to avoid jarring cuts.
* Touchdown impact:
  * Triggers `footstep_land.wav` on independent `LandingPlayer`.
