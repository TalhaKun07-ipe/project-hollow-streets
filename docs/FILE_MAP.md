# 🗺️ Project Hollow Streets — Complete File Registry & Architecture Map

This document lists every file and folder in the repository, explaining its purpose, node structure, and dependencies.

---

## 1. Directory Tree & Categorization

```text
c:\Users\USER\Desktop\saad game\
├── 📁 scenes/       # All Godot scene files (.tscn)
├── 📁 scripts/      # All GDScript game logic (.gd)
├── 📁 textures/     # All PBR architectural & terrain textures (.png)
├── 📁 assets/       # 3D models, animations, character materials & audio
├── 📁 docs/         # All project documentation (.md)
├── 📁 Saad_Hridy/   # Mirrored project root for active Godot editor
├── 📄 project.godot # Engine configuration
├── 📄 icon.svg      # Game icon
└── 📄 README.md     # Primary readme
```

---

## 2. Scenes (`scenes/`)

| File Path | Root Node Type | Description & Purpose | Instantiated By |
| :--- | :--- | :--- | :--- |
| **`scenes/main.tscn`** | `Node3D` | **Main Level & City World.** Contains the $300\text{m} \times 300\text{m}$ ground, road network, sidewalks, 36 streetlamps, 24 buildings, 4 boundary collision walls, directional moonlight, volumetric fog environment, and background music player. | Project Startup (`project.godot`) |
| **`scenes/player.tscn`** | `CharacterBody3D` | **Player Character Prefab.** Contains collision capsule, character model instance (`saad_model_animated.tscn`), camera boom (`SpringArm3D` + `Camera3D`), physical flashlight (`Torch`), and audio players (`FootstepPlayer`, `LandingPlayer`, `FlashlightPlayer`). | `scenes/main.tscn` |
| **`scenes/saad_model_animated.tscn`** | `Node3D` | **Rigged & Animated Character.** Contains `Skeleton3D` with 65 Mixamo bones, 5 Avaturn character meshes (body, hair, shoes, look), and `AnimationPlayer` loaded with `saad_animations.tres`. | `scenes/player.tscn` |
| **`scenes/buildings/building_brick_apartment.tscn`** | `StaticBody3D` | **5-Story Residential Building.** Features brick facade, front entrance stoop, entrance canopy, double doors ($2.3\text{m}$), 12 framed windows with sills, rooftop parapet, and HVAC units. | `scenes/main.tscn` (Block B) |
| **`scenes/buildings/building_commercial_tower.tscn`** | `StaticBody3D` | **34m Modern Skyscraper.** Features concrete panels, ground-floor entrance foyer, canopy ($2.85\text{m}$), double doors ($2.5\text{m}$), lobby light, 3 illuminated glass window strips, rooftop HVAC chiller, and antenna spire. | `scenes/main.tscn` (Block A) |
| **`scenes/buildings/building_corner_shop.tscn`** | `StaticBody3D` | **2-Story Corner Storefront.** Features ground-level display windows, sloped awning canopy ($2.85\text{m}$), warm shop light, and upper residential flat. | `scenes/main.tscn` (Block C & D) |
| **`scenes/props/street_lamp.tscn`** | `StaticBody3D` | **Cast-Iron Streetlamp Post.** Features stepped base, vertical pole, angled arm bracket, lantern housing, emissive bulb mesh, `OmniLight3D` casting warm light ($12\text{m}$ range), and cylinder collider. | `scenes/main.tscn` (Sidewalks) |

---

## 3. Scripts (`scripts/`)

| File Path | Attached To | Purpose & Key Methods |
| :--- | :--- | :--- |
| **`scripts/player.gd`** | `scenes/player.tscn` | **Player Locomotion, Animation, Flashlight & Audio Controller.**<br>• `_physics_process(delta)`: Vector movement, acceleration, friction, gravity, jumping, speed-adaptive footstep pitch/fade.<br>• `_unhandled_input(event)`: Mouse look rotation, escape cursor release, flashlight toggle.<br>• `_toggle_flashlight(enable)`: Procedural tween raising/lowering, switch click audio, bulb micro-flicker.<br>• `_update_animation(delta, dir)`: Skeletal blend state transitions (`idle`, `walk`, `run`), procedural turn banking (`current_lean`), and landing recovery squash. |
| **`scripts/background_music.gd`** | `scenes/main.tscn` (`BackgroundMusic`) | **Seamless Soundtrack Looping.**<br>• Monitors playback and seamlessly loops `background_music.mp3` with automatic restart safety guards if interrupted. |

---

## 4. Textures (`textures/`)

All textures are 2048x2048 PNG PBR maps with crisp detail:

| Material Set | Files | Maps Included | Where Used |
| :--- | :--- | :--- | :--- |
| **Brick Facade** | `building_brick_facade.png`<br>`building_brick_nor.png`<br>`building_brick_rough.png` | Diffuse, Normal, Roughness | Walls of `building_brick_apartment.tscn` |
| **Concrete Panels** | `building_concrete_panels.png`<br>`building_concrete_nor.png`<br>`building_concrete_rough.png` | Diffuse, Normal, Roughness | Facade of `building_commercial_tower.tscn` |
| **Entrance Door** | `building_entrance_door.png`<br>`building_door_nor.png`<br>`building_door_rough.png` | Diffuse, Normal, Roughness | Double doors on apartments and commercial tower |
| **Storefront** | `building_storefront.png`<br>`building_storefront_nor.png`<br>`building_storefront_rough.png` | Diffuse, Normal, Roughness | Ground-floor display of `building_corner_shop.tscn` |
| **Asphalt Road** | `road_asphalt_lanes.png`<br>`road_asphalt_nor.png`<br>`road_asphalt_rough.png` | Diffuse, Normal, Roughness | Main Avenue and Cross Street road planes |
| **Zebra Crosswalk** | `road_crosswalk.png`<br>`road_crosswalk_nor.png`<br>`road_crosswalk_rough.png` | Diffuse, Normal, Roughness | 4 Intersection pedestrian crossing approaches |
| **Concrete Sidewalk** | `sidewalk_concrete.png`<br>`sidewalk_concrete_nor.png`<br>`sidewalk_concrete_rough.png` | Diffuse, Normal, Roughness | Raised concrete walkways with expansion joints and curbs |
| **Rooftop Tar & Gravel**| `roof_gravel_tar.png`<br>`roof_gravel_tar_nor.png`<br>`roof_gravel_tar_rough.png` | Diffuse, Normal, Roughness | Rooftops of all buildings |
| **Rocky Terrain** | `rocky_terrain_02_diff_4k.png`<br>`rocky_terrain_02_nor_gl_4k.png`<br>`rocky_terrain_02_rough_4k.png` | Diffuse, Normal, Roughness | $300\text{m} \times 300\text{m}$ ground plane |

---

## 5. Assets (`assets/`)

### Character Models & Animations
* **`assets/Idle.fbx`**: Mixamo idle animation FBX (8.33s loop).
* **`assets/Walking.fbx`**: Mixamo forward walk animation FBX (1.033s loop).
* **`assets/Running.fbx`**: Mixamo forward sprint animation FBX (1.066s loop).
* **`assets/saad_animations.tres`**: The active `AnimationLibrary` containing `idle`, `walk`, and `run` applied to `saad_model_animated.tscn`.
* **`assets/mat_saad_body.tres`**: StandardMaterial3D with body diffuse & normal maps.
* **`assets/mat_saad_clothes.tres`**: StandardMaterial3D with clothing diffuse & normal maps.
* **`assets/mat_saad_hair.tres`**: StandardMaterial3D with hair diffuse & normal maps.
* **`assets/mat_saad_shoes.tres`**: StandardMaterial3D with shoe diffuse & normal maps.
* **`assets/saad_model.glb`**: Original unrigged photogrammetry scan (preserved for reference).
* **`assets/new_model_tpose.glb`**: T-pose mesh used for auto-rigging.

### Audio Effects (`assets/audio/`)
* **`assets/audio/footstep_01.wav` .. `04.wav`**: Single-step asphalt footsteps.
* **`assets/audio/footstep_land.wav`**: Heavy physical touchdown impact sound for jump landings.
* **`assets/audio/flashlight_click_on.wav`**: Tactile mechanical switch click with capacitor surge for turning the torch on.
* **`assets/audio/flashlight_click_off.wav`**: Solid mechanical switch release snap for turning the torch off.

### Given Assets (`assets/saad given assets/`)
* **`assets/saad given assets/footsteps sounds.mp3`**: The active continuous footstep sound track used by the player controller.
* **`assets/saad given assets/background_music.mp3`**: The active looping background music track playing throughout the city.
* **`assets/saad given assets/Jogging.fbx`**: Alternative jogging animation clip.
* **`assets/saad given assets/Standard Walk.fbx`**: Alternative walking animation clip.
* **`assets/saad given assets/Unarmed Idle Looking Ver. 2.fbx`**: Alternative idle animation clip.

---

## 6. Documentation Suite (`docs/`)

All project documentation lives together in the `docs/` folder:

| Documentation File | Subject Covered |
| :--- | :--- |
| **[`docs/PROJECT_CONTEXT_FOR_AI.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/PROJECT_CONTEXT_FOR_AI.md)** | **Master AI Briefing:** The complete document to give to any AI model for immediate project comprehension. |
| **[`docs/FILE_MAP.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/FILE_MAP.md)** | **Complete File Registry:** This document (directory layout, file purpose, dependencies). |
| **[`docs/ARCHITECTURE.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/ARCHITECTURE.md)** | **Technical Architecture:** Engine settings, rendering pipeline, input maps, collision layers, node graphs. |
| **[`docs/GAME_DESIGN.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/GAME_DESIGN.md)** | **Game Design Document:** Narrative premise, gameplay loops, atmosphere, character bios, victory conditions. |
| **[`docs/CHARACTER_ANIMATION_GUIDE.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/CHARACTER_ANIMATION_GUIDE.md)** | **Animation Pipeline:** Mixamo rigging, skeleton retargeting, bone filters, `AnimationTree` blends. |
| **[`docs/CODING_STANDARDS.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/CODING_STANDARDS.md)** | **Coding Standards:** GDScript formatting, typing, naming conventions, safety guidelines. |
| **[`docs/DEVLOG.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/DEVLOG.md)** | **Session Devlog:** Chronological development log of all 5 development sessions. |
| **[`docs/ROADMAP.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/ROADMAP.md)** | **Production Roadmap:** Upcoming milestones (Hridy NPC, dialogue system, quest triggers, audio Polish). |
| **[`docs/README.md`](file:///c:/Users/USER/Desktop/saad%20game/docs/README.md)** | **Docs Hub:** Table of contents and navigation index for the documentation suite. |
