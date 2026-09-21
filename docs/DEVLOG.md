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
1. Apply Phase 2 environment fixes:
   - Fix ground metallic property (`metallic = 0.0` in `main.tscn`).
   - Add perimeter wall colliders so player doesn't fall off the edge.
   - Add lamppost pole 3D meshes under floating streetlights.
   - Enable volumetric fog in `WorldEnvironment`.
2. Build the Hridy character entity and interactive quest resolution trigger.

