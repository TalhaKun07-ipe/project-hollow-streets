# Developer Log (DevLog)

*Project Hollow Streets v2.0 (Saad & Hridy)*  
*Track all project modifications, architectural decisions, additions, and bug fixes chronologically.*

---

## Log Entry Template

```markdown
## [YYYY-MM-DD] - <Session Title>
### Added
- <List of new features, scenes, or assets>
### Changed
- <List of modifications to existing code or configurations>
### Fixed
- <List of bugs resolved>
### Notes / Observations
- <Key technical takeaways, performance notes, or design changes>
```

---

## [2026-09-21] - Project Discovery, Deep Codebase Audit & Documentation Architecture
**Author / Collaborators:** Saad, Friend, AI Pair Programmer

### Discovered & Analyzed
* Examined project configuration in `project.godot`:
  * Verified engine compatibility for Godot 4.7 Forward+ renderer.
  * Verified key bindings for movement (`W`, `A`, `S`, `D`), jump (`Space`), and torch (`F`).
* Audited `player.gd`:
  * Found custom procedural animation system devised to give life to an unrigged 3D photogrammetry scan mesh (`saad_model.glb`).
  * Analyzed footfall curve formula: $\text{footfall} = |\sin(\text{phase})|^{0.6}$, lateral sway, turn banking, idle breathing, and landing squash/stretch.
* Audited `main.tscn`:
  * Analyzed $120\text{m} \times 120\text{m}$ ground plane, 5 block buildings with material variants and lit/unlit windows, directional moonlight, and cyan streetlamps.
  * Checked UI labels (`Objective: Find Hridy`, `F-Torch`).
* Identified key improvement opportunities:
  * Ground metallic reflectivity issue (`metallic = 1.0`).
  * Missing Hridy NPC / goal entity.
  * Unused empty nodes in `player.tscn` (`StaticBody3D`, `Skeleton3D`, `AnimationTree`).
  * 4K PNG texture footprint (~480 MB) and duplicate `texture/textures` folder.
  * Lack of sound effects and map boundary walls.

### Added
* Created comprehensive multi-document engineering knowledge base in `docs/`:
  * **[`README.md`](../README.md)**: Main project portal, how to run with Godot 4.7, controls, and architecture index.
  * **[`docs/ARCHITECTURE.md`](ARCHITECTURE.md)**: Complete scene hierarchy, script variable specs, physics layer mapping, and procedural animation mathematics.
  * **[`docs/GAME_DESIGN.md`](GAME_DESIGN.md)**: Narrative lore, core gameplay loop, aesthetic color palette, and audio direction.
  * **[`docs/CODING_STANDARDS.md`](CODING_STANDARDS.md)**: Strict GDScript typing guidelines, naming conventions, scene encapsulation, and asset standards.
  * **[`docs/CHARACTER_ANIMATION_GUIDE.md`](CHARACTER_ANIMATION_GUIDE.md)**: Full blueprint for character renovation (3D skeletal rigging + Mixamo vs 2.5D multi-directional billboard sprite sheets with grid/frame specs).
  * **[`docs/ROADMAP.md`](ROADMAP.md)**: Phased milestones from Phase 1 through Phase 6 with interactive task checklists.
  * **[`docs/DEVLOG.md`](DEVLOG.md)**: This continuous log file.

### Added (Character Assets & Animation Overhaul)
* Converted Avaturn GLB `new model tpose` into a clean, game-ready OBJ:
  * **[`assets/new_model_tpose.obj`](../assets/new_model_tpose.obj)** (29,151 vertices, 39,333 faces, complete UV coordinates and vertex normals).
  * **[`assets/new_model_tpose.glb`](../assets/new_model_tpose.glb)** (Rigged GLB containing 52-joint Armature and embedded textures).
* Imported Mixamo animation pack: `Idle.fbx`, `Walking.fbx`, and `Running.fbx`.
* Created high-fidelity PBR materials with extracted diffuse and normal maps:
  * `assets/mat_saad_body.tres` (Face and skin)
  * `assets/mat_saad_hair.tres` (Layered hair with alpha scissor transparency)
  * `assets/mat_saad_shoes.tres` (Combat boots)
  * `assets/mat_saad_clothes.tres` (Urban exploration jacket and pants)
* Integrated animations from `assets/saad given assets/`:
  * **`Unarmed Idle Looking Ver. 2.fbx`**: Natural idle with subtle head turns and looking around.
  * **`Standard Walk.fbx`**: Smooth standard walk cycle with mathematical forward Z-drift correction for clean in-place playback.
  * **`Jogging.fbx`**: Energetic jog/sprint cycle with normalized in-place trajectory.
* Rebuilt **[`scenes/saad_model_animated.tscn`](../scenes/saad_model_animated.tscn)** with the new base mesh, complete with full PBR materials (face/skin, hair, clothes, and boots).
* Validated complete integration in Godot 4.7 Forward+ engine with 0 errors!
* Initialized Git with Git LFS (for 3D models and 4K textures) and published to private GitHub repository:
  * URL: **`https://github.com/TalhaKun07-ipe/project-hollow-streets`**

---

## 📅 Session 3 — Collaborator Compatibility Fix & Root Restructuring (Current)

### 🐛 Identified Issues on Collaborator Machines
1. **Repository Structure**: Godot project was nested inside `Saad_Hridy/`, preventing Godot Project Manager from detecting `project.godot` at the repository root when cloned or downloaded.
2. **Git LFS Pointer Corruption**: Collaborators downloading the repository as a ZIP from GitHub or cloning without Git LFS received 130-byte text pointers instead of binary `.fbx`, `.glb`, and `.png` files, causing `ufbx`, `glTF`, and PNG decode crashes in Godot.
3. **Missing `icon.svg`**: `project.godot` referenced `res://icon.svg`, which threw missing file errors on startup.
4. **Engine Version Tag**: `config/features` was locked to `"4.7"`, causing compatibility warnings on standard Godot 4.3 / 4.2 installs.
5. **Overweight 4K Textures**: 4K textures (98MB each) were causing long import times and required Git LFS.

### 🛠️ Key Fixes Implemented
* **Promoted Godot Project to Root**: Placed `project.godot`, `scenes/`, `scripts/`, `assets/`, `textures/`, `texture/`, and `docs/` directly at the repository root. Cloned repo is now immediately detected by Godot 4.
* **Eliminated Git LFS Dependency**:
  * Optimized uncompressed 4K PNG textures to crisp 2048x2048 PNGs (reducing individual file sizes from ~98 MB down to ~7-9 MB).
  * Removed all Git LFS filters from `.gitattributes`.
  * All 3D models (`.fbx`, `.glb`) and textures are now stored natively as regular Git binary blobs (< 10 MB each, total repo size < 65 MB).
  * Collaborators can now use standard `git clone` or "Download ZIP" with zero additional setup or Git LFS software required.
* **Added `icon.svg`**: Designed a clean, modern SVG vector icon for Project Hollow Streets.
* **Standardized Engine Tag**: Updated `config/features` to `"4.3", "Forward Plus"`, ensuring clean opening across all Godot 4.x versions.
* **Verified Headless Import & Game Run**: Verified that Godot imports all 58 assets in 2 seconds and runs `main.tscn` with 0 errors or warnings.

### Next Session Priorities
1. Build the Hridy character entity and interactive quest resolution trigger.
2. Add ambient city background audio and footstep sound effects.

---

## 📅 Session 4 — City World Expansion, Realistic Architectural Textures, Road Network & Volumetric Fog
**Author / Collaborators:** Saad, Friend, AI Pair Programmer

### Added
* **Photorealistic Architectural Textures & PBR Maps (`textures/`)**:
  * `building_brick_facade.png`, `building_brick_nor.png`, `building_brick_rough.png`: Realistic urban brick facade with architectural relief and dark mortar lines.
  * `building_concrete_panels.png`, `building_concrete_nor.png`, `building_concrete_rough.png`: Modern commercial office building facade with concrete panels and steel-framed window strips.
  * `building_entrance_door.png`, `building_door_nor.png`, `building_door_rough.png`: High-resolution commercial glass double doors with stone portal frame and stainless steel handles.
  * `building_storefront.png`, `building_storefront_nor.png`, `building_storefront_rough.png`: Street-level commercial storefront with glass display windows, entrance door, and signage header.
  * `road_asphalt_lanes.png`, `road_asphalt_nor.png`, `road_asphalt_rough.png`: Asphalt road surface with double-yellow center divider and dashed white lane markings.
  * `road_crosswalk.png`, `road_crosswalk_nor.png`, `road_crosswalk_rough.png`: Asphalt road crosswalk with bold zebra pedestrian crossing stripes.
  * `sidewalk_concrete.png`, `sidewalk_concrete_nor.png`, `sidewalk_concrete_rough.png`: Concrete pavement tiles with expansion joints and curb borders.
  * `roof_gravel_tar.png`, `roof_gravel_tar_nor.png`, `roof_gravel_tar_rough.png`: Rooftop tar and gravel texture.
* **Modular Architectural & Prop Scenes (`scenes/`)**:
  * **[`scenes/props/street_lamp.tscn`](../scenes/props/street_lamp.tscn)**: 3D cast-iron streetlamp with base, vertical pole, angled bracket arm, lantern housing, emissive bulb, OmniLight3D, and cylinder collider.
  * **[`scenes/buildings/building_brick_apartment.tscn`](../scenes/buildings/building_brick_apartment.tscn)**: 5-story residential brick building with front entrance stoop, canopy, entrance door, 12 framed windows (alternating lit and dark panes), rooftop parapet ledges, and HVAC units.
  * **[`scenes/buildings/building_commercial_tower.tscn`](../scenes/buildings/building_commercial_tower.tscn)**: 34m tall modern concrete & glass office tower with ground-floor entrance foyer, canopy, entrance doors, illuminated glass bands, rooftop parapet, HVAC chiller, and rooftop antenna.
  * **[`scenes/buildings/building_corner_shop.tscn`](../scenes/buildings/building_corner_shop.tscn)**: 2-story street-corner building with ground-level storefront display windows, overhanging awning canopy, shop light, and upper residential flat.
* **Urban Infrastructure & City Layout (`scenes/main.tscn`)**:
  * Expanded ground footprint to $300\text{m} \times 300\text{m}$.
  * Main Avenue (North-South): 14m wide asphalt avenue stretching 280m across the city.
  * Cross Street (East-West): 12m wide intersecting street creating a central crossroad junction.
  * Pedestrian zebra crosswalks at the 4 junction approaches.
  * 4 quadrants of raised concrete sidewalks (0.18m curbs) flanking all streets.
  * 36 streetlamp posts lining the sidewalks casting warm volumetric illumination along the streets.
  * 24 buildings populated across 4 city blocks (Downtown High-Rise, Residential Brick District, Mixed Market, and Industrial Plaza).
  * 4 perimeter boundary collision walls at $x = \pm 145$ and $z = \pm 145$ preventing the player from falling off the edge.
* **Atmospheric Volumetric Fog & Lighting (`scenes/main.tscn`)**:
  * Configured Godot 4 Volumetric Fog: `density = 0.02`, `albedo = Color(0.25, 0.32, 0.44)`, `length = 90.0m`, `ambient_inject = 0.2`.
  * Configured Distance Depth Fog: `density = 0.008`, `light_color = Color(0.12, 0.15, 0.22)`, smoothly fading distant city silhouettes into the night sky.
  * Adjusted DirectionalLight3D moonlight shadow distance to 180m for the expanded city scale.

* **Audio System & Footstep Audio Implementation (`assets/audio/`, `scripts/player.gd`, `scenes/main.tscn`)**:
  * Integrated background music track provided in `saad given assets/` (`background musics.mpeg` converted/imported as `background_music.mp3` with native Godot loop parameters).
  * Attached `AudioStreamPlayer` node `BackgroundMusic` with continuous looping script (`scripts/background_music.gd`) in `main.tscn`.
  * Generated 4 realistic asphalt/concrete footstep sound effects (`footstep_01.wav` through `footstep_04.wav`) with heel thumps, grit crunch, and toe-off taps, plus a heavier landing sound (`footstep_land.wav`).
  * Implemented procedural footstep audio system in `scripts/player.gd` that plays dynamic footsteps with pitch and volume variation scaled by movement speed (walking vs. jogging) and triggers impact audio upon landing.
  * Added `FootstepPlayer` (`AudioStreamPlayer3D`) to `scenes/player.tscn`.

### Changed
* **Ground Material**: Removed unrealistic metallic reflectivity (`metallic = 0.0`, `roughness = 0.85`), providing natural dark rock/pavement grounding.
* **Building Textures**: Completely replaced old placeholder rock wall textures on buildings with authentic architectural PBR textures.

### Verified
* Godot 4.7.2 Forward+ headless engine verification completed with **0 errors and 0 warnings** across both root and `Saad_Hridy/` project targets.

---

## 📅 Session 5 — Animation Model Restoration, Given Footsteps Audio, Visible Mist Fog, Human Proportioning & Physical Flashlight System
**Author / Collaborators:** Saad, Friend, AI Pair Programmer

### Added & Restored
* **Restored Previous FBX Animation Model & Library (`assets/saad_animations.tres`, `scenes/saad_model_animated.tscn`)**:
  * Re-bound character `AnimationPlayer` to the previous FBX animations:
    * `idle`: 8.33s linear loop from `assets/Idle.fbx`.
    * `walk`: 1.033s linear loop from `assets/Walking.fbx`.
    * `run`: 1.066s linear loop from `assets/Running.fbx`.
  * Synchronized both root project and `Saad_Hridy/` project definitions.
* **Footstep Audio from `saad given assets/` (`assets/saad given assets/footsteps sounds.mp3`)**:
  * Configured native Godot 4 MP3 stream looping on `footsteps sounds.mp3`.
  * Assigned directly to `FootstepPlayer` (`AudioStreamPlayer3D`) on `scenes/player.tscn`.
  * Implemented dynamic rhythm tracking in `scripts/player.gd`:
    * Smooth volume fade-in and pitch modulation (`pitch_scale = 0.95` walking, `1.35` sprinting).
    * Smooth fade-out and pause when idle or in mid-air to prevent repetitive stuttering.
    * Independent `LandingPlayer` for physical touchdown impact audio upon landing.
* **Distinctly Visible Volumetric & Atmospheric Mist (`scenes/main.tscn`)**:
  * Increased `volumetric_fog_density` from `0.02` to `0.065`.
  * Upgraded volumetric albedo to crisp moonlight mist `Color(0.55, 0.65, 0.78, 1)`.
  * Raised `volumetric_fog_ambient_inject` to `0.55` and added subtle mist emission.
  * Increased depth fog density to `0.022` with light scattering `Color(0.25, 0.32, 0.45, 1)`.
* **Physical Flashlight Interaction & Procedural Tweening (`scripts/player.gd`, `scenes/player.tscn`)**:
  * Generated crisp mechanical switch sound effects:
    * `assets/audio/flashlight_click_on.wav`: Tactile switch click with filament surge.
    * `assets/audio/flashlight_click_off.wav`: Solid plastic/metal release snap.
  * Attached `FlashlightPlayer` (`AudioStreamPlayer3D`) to player torch.
  * Implemented procedural raise/lower drawing motion via `Tween`:
    * When toggled ON: Smoothly raises forward to aiming position, plays click audio, and triggers realistic 0.09s micro-flicker (bulb warm-up).
    * When toggled OFF: Plays click-off audio, cuts light, and smoothly lowers torch toward the character's hip where the physical flashlight mesh stays visible on the character body (instead of vanishing).
* **Character-to-Building Scale & Perspective Calibration**:
  * Scaled Saad model by +12% (`scale = Vector3(-112, 112, -112)`), providing a 2.04m heroic third-person protagonist silhouette.
  * Tightened camera FOV from `80.9°` down to `70.0°` and shortened spring arm distance from `4.2m` to `3.3m`, eliminating wide-angle lens distortion.
  * Rescaled oversized building entrance doors and canopies to realistic human architectural heights:
    * `building_brick_apartment.tscn`: Door scaled from 3.6m down to 2.3m; canopy lowered from 4.05m to 2.75m.
    * `building_commercial_tower.tscn`: Double doors scaled from 4.0m down to 2.5m; canopy lowered from 4.4m to 2.85m.
    * `building_corner_shop.tscn`: Awning lowered from 4.3m down to 2.85m; storefront lights at 2.65m.

### Verified
* Automated test suite executed in Godot 4.7.2 Forward+ headless mode:
  * Fog density and volumetric mist verified active.
  * AnimationPlayer verified loaded with previous 8.33s idle, 1.03s walk, and 1.07s run.
  * FootstepPlayer verified bound to `footsteps sounds.mp3`.
  * Flashlight raise/lower tween, click audio, and light toggle verified functional.
* Both root and `Saad_Hridy` projects run with 0 errors.




