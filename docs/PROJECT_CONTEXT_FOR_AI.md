# 🤖 Project Hollow Streets — Master AI Onboarding & Context Brief

> **Purpose of this Document:**  
> This file is the single source of truth for **Project Hollow Streets**. Provide this document (or point to it) to any AI assistant (ChatGPT, Claude, Cursor, Gemini, DeepSeek, Copilot, etc.) to give it immediate, complete, and deep understanding of the project's design, code architecture, directory structure, asset dependencies, and strict development rules without needing to inspect every file manually.

---

## 1. Executive Summary & Narrative Premise

| Property | Value |
| :--- | :--- |
| **Project Title** | Project Hollow Streets (v2.0) |
| **Engine & Renderer** | **Godot 4.7.2** / **Godot 4.3+** (Forward+ Desktop Renderer) |
| **Genre** | Atmospheric Third-Person Mystery / Exploration Adventure |
| **Perspective** | Third-person behind-the-back over-the-shoulder (`SpringArm3D` + `Camera3D`) |
| **Inspirations** | *Kingdom Hearts* (responsive locomotion, jump physics, camera feel), *Alan Wake* (tactile flashlight, night shadow casting), *Silent Hill* (heavy volumetric street fog, psychological dread). |
| **Protagonist** | **Saad** — Dressed in an overcoat, equipped with a heavy flashlight, exploring a dark, misty city at 2:00 AM. |
| **Core Objective** | Search the empty urban blocks, follow environmental clues, and locate **Hridy**. |
| **Repository Root** | `c:\Users\USER\Desktop\saad game\` (primary Godot project root) |
| **Secondary Subfolder** | `c:\Users\USER\Desktop\saad game\Saad_Hridy\` (active editor folder — **all changes must be mirrored here**) |

---

## 2. Complete Project Directory Structure ("What Has What")

The codebase is organized into clean, dedicated functional directories:

```text
c:\Users\USER\Desktop\saad game\
├── project.godot               # Primary Godot 4 engine configuration
├── icon.svg                    # Vector game project icon
├── README.md                   # Human-facing project overview & quickstart
│
├── scenes/                     # ALL Godot .tscn scene prefabs
│   ├── main.tscn               # Main level: 300x300m world, roads, sidewalks, lighting, buildings, fog
│   ├── player.tscn             # CharacterBody3D player prefab (camera, physics, flashlight, audio)
│   ├── saad_model_animated.tscn# Rigged character model with Skeleton3D, Avaturn meshes, and AnimationPlayer
│   │
│   ├── buildings/              # Modular architectural building prefabs
│   │   ├── building_brick_apartment.tscn   # 5-story brick apartment building with stoop, door, windows, AC
│   │   ├── building_commercial_tower.tscn  # 34m concrete & glass corporate skyscraper with lobby & antenna
│   │   └── building_corner_shop.tscn       # 2-story corner market with ground-floor storefront & awning
│   │
│   └── props/                  # World furniture and interactive props
│       └── street_lamp.tscn    # Cast-iron streetlamp with OmniLight3D, collision, and emissive bulb
│
├── scripts/                    # ALL GDScript (.gd) logic files
│   ├── player.gd               # Character physics, skeletal animations, footstep audio, procedural flashlight
│   └── background_music.gd     # Seamless, resilient background music loop controller
│
├── textures/                   # ALL photorealistic PBR material maps (2048x2048 PNGs)
│   ├── building_brick_facade.png, building_brick_nor.png, building_brick_rough.png
│   ├── building_concrete_panels.png, building_concrete_nor.png, building_concrete_rough.png
│   ├── building_entrance_door.png, building_door_nor.png, building_door_rough.png
│   ├── building_storefront.png, building_storefront_nor.png, building_storefront_rough.png
│   ├── road_asphalt_lanes.png, road_asphalt_nor.png, road_asphalt_rough.png
│   ├── road_crosswalk.png, road_crosswalk_nor.png, road_crosswalk_rough.png
│   ├── sidewalk_concrete.png, sidewalk_concrete_nor.png, sidewalk_concrete_rough.png
│   ├── roof_gravel_tar.png, roof_gravel_tar_nor.png, roof_gravel_tar_rough.png
│   └── rocky_terrain_02_diff_4k.png, rocky_terrain_02_nor_gl_4k.png, rocky_terrain_02_rough_4k.png
│
├── assets/                     # 3D binary models, skeletal animations, materials & audio
│   ├── Idle.fbx                # Mixamo breathing idle FBX (8.33s clip)
│   ├── Walking.fbx             # Mixamo forward walk cycle FBX (1.033s clip)
│   ├── Running.fbx             # Mixamo forward sprint cycle FBX (1.066s clip)
│   ├── saad_animations.tres    # Extracted AnimationLibrary containing loopable 'idle', 'walk', 'run'
│   │
│   ├── mat_saad_body.tres      # StandardMaterial3D for Saad's head and skin
│   ├── mat_saad_clothes.tres   # StandardMaterial3D for jacket and trousers
│   ├── mat_saad_hair.tres      # StandardMaterial3D for hair meshes
│   ├── mat_saad_shoes.tres     # StandardMaterial3D for boots
│   │
│   ├── audio/                  # Generated procedural sound effects (16-bit WAV)
│   │   ├── footstep_01.wav .. 04.wav   # Individual asphalt footstep taps
│   │   ├── footstep_land.wav           # Heavy physical touchdown impact upon landing
│   │   ├── flashlight_click_on.wav     # Tactile mechanical switch click + filament buzz
│   │   └── flashlight_click_off.wav    # Solid mechanical switch release snap
│   │
│   └── saad given assets/      # User-provided audio and reference clips
│       ├── footsteps sounds.mp3        # Continuous 7.58s rhythmic footstep recording (active stream)
│       ├── background_music.mp3        # Ambient atmospheric soundtrack (active stream)
│       ├── Jogging.fbx                 # Reference Mixamo jogging animation
│       ├── Standard Walk.fbx           # Reference Mixamo walking animation
│       └── Unarmed Idle Looking Ver. 2.fbx # Reference Mixamo idle animation
│
└── docs/                       # Project Documentation Suite
    ├── PROJECT_CONTEXT_FOR_AI.md # THIS FILE — Master AI onboarding brief
    ├── FILE_MAP.md             # Detailed index of all files, paths, and dependencies
    ├── ARCHITECTURE.md         # Technical architecture and systems specification
    ├── GAME_DESIGN.md          # Game design document (narrative, gameplay loops, mechanics)
    ├── CHARACTER_ANIMATION_GUIDE.md # Guide to character rigging, Mixamo pipeline, and animation trees
    ├── CODING_STANDARDS.md     # GDScript style guide, architecture rules, and safety practices
    ├── DEVLOG.md               # Historical devlog of all development sessions
    ├── ROADMAP.md              # Milestones, upcoming quests, and feature plans
    └── README.md               # Documentation directory index
```

---

## 3. Core Systems Breakdown

### 3.1 Character Controller & Locomotion (`scripts/player.gd`)
* **Base Class:** `CharacterBody3D` (Collision layer: 2, `floor_max_angle: 0.8 rad`).
* **Speeds:** Walking speed = $4.5\text{ m/s}$, Sprint speed (Hold Shift) = $7.5\text{ m/s}$, Jump velocity = $6.2\text{ m/s}$.
* **Acceleration / Friction:** Smooth vector acceleration ($14.0$) and friction ($12.0$) with `move_and_slide()`.
* **Dynamic Visual Juice:**
  * **Procedural Turn Banking:** Body rolls into turns (`saad_model.rotation.z = -current_lean`) based on angular velocity.
  * **Landing Recovery:** Jump touchdowns trigger vertical squash-and-stretch (`landing_squash = 0.12`) over $0.12\text{s}$.
  * **Camera Boom:** `SpringArm3D` ($3.3\text{m}$ length, $1.7\text{m}$ height) with clamped pitch ($-55^\circ$ to $+30^\circ$) and mouse capture. `Camera3D.fov = 70.0^\circ$.
* **Safety Fallback:** If global $Y < -15.0$, player respawns automatically at $(0, 2.5, 0)$.

### 3.2 Skeletal Animation System (`scenes/saad_model_animated.tscn`)
* **Mesh:** High-quality humanoid scan mesh (`avaturn_body`, `avaturn_hair_0`, `avaturn_hair_1`, `avaturn_shoes_0`, `avaturn_look_0`).
* **Skeleton:** 65-bone Mixamo humanoid rig targeting `mixamorig_*` bones.
* **Animation Library:** `res://assets/saad_animations.tres`:
  * `idle`: $8.33\text{s}$ breathing/posture linear loop (from `assets/Idle.fbx`).
  * `walk`: $1.033\text{s}$ walk cycle (from `assets/Walking.fbx`), playback speed scaled dynamically by `current_speed / walk_speed`.
  * `run`: $1.066\text{s}$ sprint cycle (from `assets/Running.fbx`), playback speed scaled dynamically by `current_speed / run_speed`.
  * Cross-fade transition time: $0.25\text{s}$.

### 3.3 Flashlight & Interaction System
* **Why procedural?** Standard character rigs don't have dedicated mocap for holding a light across all movements. Instant on/off popping feels cheap.
* **Procedural Drawing & Holstering:**
  * **Toggle ON (`F`):** Smooth $0.22\text{s}$ `Tween` raises the flashlight from hip height to forward pointing pose (`(0.35, 1.25, -0.2)`), plays `flashlight_click_on.wav`, and triggers a $0.09\text{s}$ xenon/bulb micro-flicker ($0 \rightarrow 3.2 \rightarrow 0.8 \rightarrow 5.2$ energy).
  * **Toggle OFF (`F`):** Plays `flashlight_click_off.wav`, cuts the light beam, and smoothly lowers the torch to hip resting pose (`(0.28, 0.85, 0.05)`) over $0.26\text{s}$.
  * **Persistent Mesh:** The physical flashlight mesh **never disappears**; it remains visible clipped at Saad's hip when not illuminated.
* **SpotLight3D Parameters:** `energy = 5.2`, `indirect_energy = 1.6`, `spot_range = 75.0m`, `spot_angle = 42.0^\circ`, `shadow_enabled = true`.

### 3.4 Audio Subsystem
1. **Background Music:** Controlled by `scripts/background_music.gd` attached to `main.tscn`. Plays `assets/saad given assets/background_music.mp3` with native Godot loop parameters. Handles auto-restart if interrupted.
2. **Footsteps Audio:** Driven by `FootstepPlayer` (`AudioStreamPlayer3D`) in `player.gd`:
   * Uses `assets/saad given assets/footsteps sounds.mp3` as a continuous looping stream.
   * Modulates pitch dynamically with speed: `pitch_scale = 0.95` (walking) to `1.35` (running).
   * Fades volume down and pauses smoothly when stationary or airborne, resuming seamlessly without stuttering.
3. **Landing Impact:** Independent `LandingPlayer` triggers `assets/audio/footstep_land.wav` on touchdown.
4. **Flashlight Clicks:** `FlashlightPlayer` plays `flashlight_click_on.wav` and `flashlight_click_off.wav` at torch 3D coordinates.

### 3.5 World & Environment Architecture (`scenes/main.tscn`)
* **Scale:** $300\text{m} \times 300\text{m}$ ground plane (`rocky_terrain_02` PBR material, non-metallic).
* **Road Network:**
  * North-South Main Avenue ($14\text{m}$ wide, $280\text{m}$ length, asphalt with lane markings).
  * East-West Cross Street ($12\text{m}$ wide).
  * 4 Pedestrian zebra crosswalks at the intersection.
  * Raised concrete sidewalks ($4\text{m}$ wide, $0.18\text{m}$ curb) flanking all streets.
* **Lighting:**
  * 36 Cast-iron streetlamps lining all sidewalks (`scenes/props/street_lamp.tscn`).
  * Warm OmniLight3D pools with volumetric light scattering.
  * DirectionalLight3D moonlight casting $180\text{m}$ shadows.
* **Atmospheric Volumetric Fog:**
  * `volumetric_fog_enabled = true`, `density = 0.065`.
  * `volumetric_fog_albedo = Color(0.55, 0.65, 0.78, 1)` (cool moonlight mist).
  * `volumetric_fog_ambient_inject = 0.55`, `volumetric_fog_length = 75.0m`.
  * Depth fog: `fog_enabled = true`, `density = 0.022`, `light_color = Color(0.25, 0.32, 0.45, 1)`.
* **Modular Buildings:**
  * 24 buildings across 4 city blocks.
  * Residential brick apartments, commercial office skyscrapers, and corner retail shops.
  * Doors scaled to human height ($2.3\text{m} - 2.5\text{m}$), canopies at $2.75\text{m} - 2.85\text{m}$.
* **Boundary Walls:** 4 collision barriers at $X = \pm 145\text{m}, Z = \pm 145\text{m}$.

---

## 4. CRITICAL RULES & GOTCHAS FOR AI AGENTS

> [!CAUTION]
> ### 1. THE DUAL-ROOT SYNCHRONIZATION RULE
> There are two active directories in this workspace:
> 1. `c:\Users\USER\Desktop\saad game\` (Repository / Primary Root)
> 2. `c:\Users\USER\Desktop\saad game\Saad_Hridy\` (Active Godot Editor Process Root)
>
> **The user's active running Godot editor is currently open on `Saad_Hridy/`.**  
> Whenever you modify, create, or delete any scene (`.tscn`), script (`.gd`), material (`.tres`), shader, or texture in the root project, **YOU MUST IMMEDIATELY COPY THE EXACT SAME CHANGES INTO `Saad_Hridy/`**, or the user will not see the changes inside their running editor!

> [!IMPORTANT]
> ### 2. HUMAN SCALE & PROPORTION INTEGRITY
> Maintain realistic human proportions:
> - **Saad's Model Scale:** `Vector3(-112, 112, -112)` ($2.04\text{m}$ tall hero protagonist).
> - **Collision Capsule:** `height = 2.05m`, `radius = 0.45m`, `y = 1.025m`.
> - **Camera FOV:** Keep at `70.0^\circ` (never increase to $\ge 80^\circ$ as wide lenses dwarf third-person characters).
> - **Camera Boom:** `spring_length = 3.3m`, `y-offset = 1.7m`.
> - **Standard Doors:** Height must be $2.2\text{m} - 2.5\text{m}$, width $1.4\text{m} - 2.2\text{m}$. Never make doors $3.5\text{m}+$ tall.
> - **Canopies & Awnings:** Height must be $2.7\text{m} - 2.9\text{m}$.

> [!WARNING]
> ### 3. AUDIO LOOPING & PLAYBACK SAFETY
> - `footsteps sounds.mp3` is a continuous $7.58\text{s}$ track. Never play it as a timer-based one-shot; always use continuous stream looping with speed pitch-modulation and volume fade.
> - Always check `if is_inside_tree():` before calling `.play()` on any `AudioStreamPlayer` or `AudioStreamPlayer3D` to prevent headless test assertions.
> - Do not include `uid="..."` in `.tscn` `[ext_resource]` entries for custom audio files if it causes invalid UID mismatch warnings between root and subfolder.

> [!NOTE]
> ### 4. NO GIT LFS DEPENDENCY
> All 3D models (`.fbx`, `.glb`) and textures (`.png`) are stored as regular binary files under $10\text{MB}$. Do not introduce Git LFS pointer files or giant uncompressed 4K PNGs that would corrupt downloads for collaborators.

---

## 5. Upcoming Development Roadmap

Any AI picking up this project should prioritize the following milestones:
1. **Milestone 1 — Hridy NPC & Visual Beacon:**
   * Create `scenes/hridy.tscn` (female character model with distinctive jacket/scarf).
   * Place Hridy in a moody alleyway alcove with a subtle light/particle trace.
2. **Milestone 2 — Quest Trigger & Dialogue Overlay:**
   * Add an `Area3D` proximity trigger around Hridy.
   * When Saad enters the area: camera smoothly cuts to cinematic two-shot, displays a stylish subtitle box with character dialogue, and marks the quest complete.
3. **Milestone 3 — Interactive Environmental Clues:**
   * Drop interactable items (notes, dropped keys, graffiti arrows) guiding the player toward Hridy.
   * Floating `[E] Inspect` UI prompt.
4. **Milestone 4 — Ambient Soundscape:**
   * Distant city sirens, wind whistling through alleyways, and electrical transformer hum near streetlamps.
