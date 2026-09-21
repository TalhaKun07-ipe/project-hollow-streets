# Technical Architecture & Systems Specification

*Project Hollow Streets v2.0 (Saad & Hridy)*  
*Engine: Godot 4.7.2 Forward+ Rendering Pipeline*

---

## 1. Engine & Project Configuration

The project is configured via [`project.godot`](file:///c:/Users/USER/Desktop/saad%20game/Saad_Hridy/project.godot).

### Key Parameters:
* **Engine Version:** Godot 4.7 (Config features: `["4.7", "Forward Plus"]`)
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
* **Layer 1 (`world`):** Static world collision geometry (Ground, buildings, walls, obstacles).
* **Layer 2 (`player`):** Player character collider (`CharacterBody3D`).
* *(Planned)* **Layer 3 (`interactable`):** Notes, items, clues, doors.
* *(Planned)* **Layer 4 (`npc`):** Hridy / other characters.

---

## 4. Scene Architecture & Hierarchies

### A. Player Scene (`res://scenes/player.tscn`)

The player is constructed as a self-contained `CharacterBody3D` prefab.

```
Player (CharacterBody3D) [Collision Layer: 2 (player), floor_max_angle: 0.8 rad (~45°)]
 ├── CollisionShape3D (CapsuleShape3D, radius: 0.4m, height: 1.85m, y-offset: 0.925m)
 ├── SaadModel (ExtResource: assets/saad_model.glb)
 │    └── [Rigid scanned mesh of Saad, rotated 180° on Y, positioned at Y=0.99m]
 ├── SpringArm3D (Camera boom: length: 4.2m, margin: 0.25m, y-offset: 1.6m)
 │    └── Camera3D (current: true, fov: 80.9°)
 ├── Torch (Node3D, offset position: (0.42, 1.15, -0.18))
 │    ├── TorchMesh (MeshInstance3D: CylinderMesh handle)
 │    └── SpotLight3D (range: 72.4m, energy: 5.0, color: (1, 0.85, 0.55), shadows: true)
 ├── StaticBody3D [Unused empty node - candidate for cleanup]
 ├── Skeleton3D [Unused empty node - placeholder for rigged mesh]
 └── AnimationTree [Unused empty node - placeholder for skeletal animations]
```

### B. Main World Scene (`res://scenes/main.tscn`)

The main game environment representing the city block at night:

```
Main (Node3D)
 ├── WorldEnvironment (ProceduralSkyMaterial, background_mode: 2)
 ├── DirectionalLight3D (Moonlight: angle (0.866, -0.353, 0.353), color: (0.5, 0.57, 0.84), energy: 0.45, shadows: true)
 ├── Ground (StaticBody3D)
 │    ├── MeshInstance3D (PlaneMesh 120m x 120m, StandardMaterial3D with 4K rocky terrain textures)
 │    └── CollisionShape3D (BoxShape3D: 120m x 1m x 120m, y-offset: -0.5m)
 ├── Player (Instance of res://scenes/player.tscn, initial spawn: (0, 0.1, 0))
 ├── Buildings (Node3D)
 │    ├── Building1 (StaticBody3D, pos: (-12, 6, -18), size: 8x12x8, Rust material, 3 windows)
 │    ├── Building2 (StaticBody3D, pos: (15, 6, -22), size: 8x12x8, Concrete material, 3 windows)
 │    ├── Building3 (StaticBody3D, pos: (-8, 5, 20), size: 8x12x8, Soot material)
 │    ├── Building4 (StaticBody3D, pos: (18, 7, 12), size: 8x12x8, Brick material, 2 windows)
 │    └── Building5 (StaticBody3D, pos: (-20, 5, 5), size: 8x12x8, Green concrete material)
 ├── StreetLamp1 (OmniLight3D, pos: (-5, 4.5, -8), color: cyan (0.58, 0.85, 0.95), energy: 1.8, shadows: true)
 ├── StreetLamp2 (OmniLight3D, pos: (10, 4.5, 5), color: cyan (0.64, 0.83, 0.97), energy: 1.5, shadows: true)
 ├── world light (OmniLight3D, pos: (-1.85, 21.9, 1.02), ambient fill, color: cyan (0.29, 1.0, 1.0), range: 111m)
 └── UI (CanvasLayer)
      ├── Objective (Label: "Objective : Find Hridy", centered top, green-tinted text)
      └── Hint (Label: "F-Torch", bottom left, orange-tinted text)
```

---

## 5. Script Breakdown: `player.gd`

File: [`scripts/player.gd`](file:///c:/Users/USER/Desktop/saad%20game/Saad_Hridy/scripts/player.gd)  
Extends: `CharacterBody3D`

### 5.1 Player State & Configuration Properties

* **Locomotion:**
  * `walk_speed: float = 4.5` m/s
  * `run_speed: float = 7.5` m/s (activated while holding `Shift`)
  * `jump_velocity: float = 6.2` m/s
  * `acceleration: float = 14.0` m/s²
  * `friction: float = 12.0` m/s²
  * `gravity`: Inherited from Godot project settings (`ProjectSettings.get_setting("physics/3d/default_gravity")`, approx 9.8 m/s²).
* **Camera & Controls:**
  * `mouse_sensitivity: float = 0.0025`
  * `camera_distance: float = 4.2` meters

### 5.2 Procedural Animation Math (Handling the Rigid Unrigged Mesh)

`saad_model.glb` is an unrigged 3D photogrammetry / scan mesh without bones or an internal `Skeleton3D`. Instead of gliding statically across the floor, `player.gd` implements an advanced procedural motion system:

#### 1. Asymmetrical Footstep Bobbing
Rather than a standard harmonic $\sin(t)$ bob (which looks floaty), the script simulates foot strikes using a sharpened non-linear curve:
$$\text{phase} = \text{timer} \pmod{2\pi}$$
$$\text{raw} = |\sin(\text{phase})|$$
$$\text{footfall} = \text{raw}^{0.6}$$
$$\text{bob\_offset} = (\text{footfall} - 0.35) \times \text{bob\_amount} \times \text{speed\_factor}$$
* This gives a rapid drop followed by an eased upward rebound, producing the visual sensation of feet hitting the ground twice per stride.

#### 2. Lateral Body Sway
$$\text{sway\_offset} = \sin(\text{timer} \times 0.5) \times \text{sway\_amount} \times \text{speed\_factor}$$
* Displaces the mesh on the local X axis at half the frequency of the vertical bob, alternating weight from left foot to right foot.

#### 3. Banking / Turn Leaning
To prevent the "statue sliding on ice" look, the model tilts into turns by calculating the local movement direction:
```gdscript
var local_dir := transform.basis.inverse() * move_dir
target_lean = clampf(-local_dir.x, -1.0, 1.0) * lean_amount
current_lean = lerpf(current_lean, target_lean, delta * 8.0)
saad_model.rotation.z = -current_lean
```

#### 4. Forward Running Pitch
When moving forward, the model pitches forward slightly:
$$\text{rot}_x = \text{deg\_to\_rad}(2.5^\circ) \times \text{speed\_factor}$$

#### 5. Idle Breathing Sway
When stationary:
$$\text{breathe} = \sin(\text{idle\_timer} \times 1.4) \times 0.012$$
Smoothly blended with `lerpf` to simulate natural chest and shoulder elevation.

#### 6. Landing Squash & Stretch
When transitioning from airborne (`not was_on_floor`) to grounded (`is_on_floor()`):
* A `landing_timer = 0.12` is triggered.
* The mesh scales dynamically along $Y$ (compression) and $X, Z$ (expansion) to preserve perceived volume:
$$\text{squash} = \sin\left(\frac{t}{0.12} \times \pi\right) \times 0.14$$
$$\text{scale} = \text{base\_scale} \times (1.0 + 0.5 \times \text{squash},\ 1.0 - \text{squash},\ 1.0 + 0.5 \times \text{squash})$$

---

## 6. Known Technical Debt & Optimization Items

1. **Dead Nodes in `player.tscn`:**
   * Empty `StaticBody3D`, `Skeleton3D`, and `AnimationTree` nodes should be removed or commented out until a rigged skeleton is imported.
2. **Ground Material Reflectivity:**
   * `metallic = 1.0` on the asphalt/rock ground in `main.tscn` creates unnatural chrome-like reflections under directional light. Needs `metallic = 0.0`.
3. **Texture Memory Footprint:**
   * The project currently stores uncompressed 4K PNG files (~100 MB each) in two separate directories (`textures/` and `texture/textures/`). These consume ~480 MB on disk and significant VRAM. Should be converted to VRAM-compressed WebP or 2K resolution.
4. **Boundary Enclosure:**
   * Ground plane is $120\text{m} \times 120\text{m}$, with a reset threshold at $Y = -15$. Invisible collision walls or street barricades should enclose the playable area.
