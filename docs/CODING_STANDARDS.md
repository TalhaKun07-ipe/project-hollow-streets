# Coding & Asset Pipeline Standards

*Project Hollow Streets v2.0 (Saad & Hridy)*

---

## 1. GDScript Best Practices

All scripts written for this project should follow standard Godot 4 idioms and best practices.

### 1.1 Strong Static Typing
Always specify explicit types for variables, parameters, and function return values to enable editor autocompletion, performance optimizations, and compile-time error detection.

```gdscript
# PREFERRED:
@export var walk_speed: float = 4.5
var current_target: Node3D = null

func calculate_velocity(input_vector: Vector2, delta: float) -> Vector3:
    var dir: Vector3 = Vector3(input_vector.x, 0.0, input_vector.y)
    return dir * walk_speed

# AVOID:
var walk_speed = 4.5
func calculate_velocity(input_vector, delta):
    ...
```

### 1.2 Naming Conventions
* **Classes & Singletons:** `PascalCase` (e.g. `GameManager`, `PlayerController`)
* **Functions & Variables:** `snake_case` (e.g. `walk_speed`, `get_ground_normal()`)
* **Constants & Enums:** `SCREAMING_SNAKE_CASE` (e.g. `MAX_BATTERY_LEVEL`)
* **Private / Internal Functions:** Prefix with an underscore `_` (e.g. `_animate()`, `_on_interact_pressed()`)
* **Scene Files (`.tscn`) & Scripts (`.gd`):** `snake_case.tscn`, `snake_case.gd`

### 1.3 Node Access Patterns
* Prefer `@onready` variables with typed nodes over repeating `get_node(...)` in process loops.
* Use `%UniqueNames` or clean direct path references within the scene boundary.
* Avoid traversing *up* the tree with `get_parent().get_parent()`. Use **Signals** for upward communication ("Call down, signal up").

```gdscript
# Preferred
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var torch_light: SpotLight3D = %TorchLight
```

---

## 2. Scene Organization & Architecture

### 2.1 Scene Encapsulation
* Every interactive or gameplay entity (Player, Prop, NPC, Clue) should be an independent, self-contained scene (`.tscn`).
* An instanced scene should be able to run and function without crashing if tested in isolation (Press `F6` in Godot).

### 2.2 Scene Tree Structure
Organize nodes logically using clear categories:
```
EntityRoot (CharacterBody3D or StaticBody3D)
 ├── CollisionShape3D
 ├── Visual (MeshInstance3D or Model scene)
 ├── Lights (if applicable)
 ├── Audio (AudioStreamPlayer3D)
 └── InteractionZone (Area3D)
```

---

## 3. Physics & Collision Layer Matrix

Always assign nodes to specific named collision layers to prevent accidental or unnecessary collision calculations:

| Layer Index | Name | Assigned To | Collides With |
| :---: | :--- | :--- | :--- |
| **1** | `world` | Ground, buildings, static street geometry | Player, Physics Props, Raycasts |
| **2** | `player` | Player CharacterBody3D | World, Hazards, Triggers |
| **3** | `interactable` | Collectible notes, clues, doors | Player Raycast / Interaction Area |
| **4** | `npc` | Hridy, other characters | World, Player |
| **5** | `triggers` | Level boundary resets, objective zones | Player |

---

## 4. Asset Pipeline & Optimization Rules

### 4.1 Folder Structure
Maintain a single, clean directory layout:
* `assets/` - 3D models (`.glb`, `.gltf`, `.blend`) and raw meshes.
* `textures/` - Image textures (`.png`, `.webp`, `.jpg`). *Note: Do not create nested `texture/textures` directories.*
* `audio/` - Sound effects (`.wav`) and background music/ambiance (`.ogg`).
* `scenes/` - Reusable scene files (`.tscn`).
* `scripts/` - GDScript files (`.gd`).
* `docs/` - Documentation files (`.md`).

### 4.2 Texture Resolution & Compression
* Avoid raw, uncompressed 4K PNG files for secondary props or distant buildings.
* Ground and primary walls: Max 2K resolution is usually more than sufficient for high fidelity while reducing disk and VRAM overhead by 75%.
* In Godot's Import dock:
  * 3D textures should be imported as **VRAM Compressed (VRAM Compression / Basis Universal / BPTC)**.

### 4.3 Audio Format Standards
* **Sound Effects (SFX):** Use uncompressed **WAV** format (`.wav`) for low latency playback (footsteps, flashlight switch, pickup clicks).
* **Music & Long Ambiance:** Use **OGG Vorbis** format (`.ogg`) for compressed, memory-efficient looping audio.

---

## 5. Documentation Maintenance

Whenever a new feature, scene, mechanic, or refactoring is introduced:
1. Update [`docs/DEVLOG.md`](DEVLOG.md) with what was added or altered.
2. If new inputs or scenes were added, update [`docs/ARCHITECTURE.md`](ARCHITECTURE.md).
3. If new design decisions were made, update [`docs/GAME_DESIGN.md`](GAME_DESIGN.md).
4. Update [`docs/ROADMAP.md`](ROADMAP.md) to check off completed items.
