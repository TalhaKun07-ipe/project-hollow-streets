# Master Development Roadmap

*Project Hollow Streets v2.0 (Saad & Hridy)*

---

## 🎯 High-Level Milestones

| Phase | Milestone | Focus Area | Status |
| :---: | :--- | :--- | :---: |
| **Phase 1** | **Foundational Audit & Documentation** | Code review, bug analysis, master docs creation | 🟢 **Complete** |
| **Phase 2** | **World Atmosphere & Environment Fixes** | Volumetric fog, lamppost poles, street boundaries, ground metallic fix | 🟡 **Next** |
| **Phase 3** | **Character Renovation (Saad Overhaul)** | 3D Skeletal rigging (Mixamo), custom PBR textures, walk/run blending | 🟢 **Complete** |
| **Phase 4** | **Hridy NPC & Quest Resolution** | Spawn Hridy, proximity trigger, dialogue/ending screen | ⚪ Planned |
| **Phase 5** | **Audio & Immersion System** | Footstep SFX (synced to footfall math), torch click, wind ambiance | ⚪ Planned |
| **Phase 6** | **Interaction & Clue Mechanics** | Interactable notes (`E` prompt), story clues, battery system | ⚪ Planned |
| **Phase 7** | **UI, Polish & Menus** | Pause menu, controls remapping, camera sensitivity, title screen | ⚪ Planned |

---

## Detailed Task Breakdown

### Phase 1: Foundational Audit & Documentation 🟢
- [x] Analyze existing Godot project files, scenes (`main.tscn`, `player.tscn`), and scripts (`player.gd`).
- [x] Document mathematical procedural animation system.
- [x] Create standardized `.md` documentation suite:
  - [x] `README.md` (Project overview & launch instructions)
  - [x] `docs/ARCHITECTURE.md` (Scene hierarchies, GDScript breakdowns, node relationships)
  - [x] `docs/GAME_DESIGN.md` (Narrative, core loop, aesthetic and audio guidelines)
  - [x] `docs/CODING_STANDARDS.md` (GDScript conventions, collision layer setup, asset optimization)
  - [x] `docs/ROADMAP.md` (This document)
  - [x] `docs/DEVLOG.md` (Continuous work log)

---

### Phase 2: World Atmosphere & Environment Polish 🟡
- [ ] **Fix Ground Material Reflectivity:** Change `metallic = 1.0` to `metallic = 0.0` in `main.tscn` so the rocky asphalt doesn't reflect like a mirror.
- [ ] **Volumetric Fog Implementation:** Configure Godot 4's `WorldEnvironment` with volumetric fog to create drifting nighttime mist and realistic light shafts from the torch and streetlamps.
- [ ] **Lamppost Geometry:** Add 3D lamppost pole meshes beneath `StreetLamp1` and `StreetLamp2` so lights aren't floating in mid-air.
- [ ] **Perimeter Barriers:** Add invisible wall collision boxes around the $120\text{m} \times 120\text{m}$ ground perimeter to prevent accidental falling off the map edge.
- [ ] **Clean Up Dead Nodes:** Remove or clean up empty placeholder nodes (`StaticBody3D`, `Skeleton3D`, `AnimationTree`) in `player.tscn`.
- [ ] **Folder Structure Consolidation:** Unify the redundant `texture/textures/` folder into the main `textures/` directory.

---

### Phase 3: Hridy NPC & Objective Resolution ⚪
- [ ] **Hridy Scene (`scenes/hridy.tscn`):** Create an NPC character entity (model or styled silhouette) stationed in an alleyway or behind a building.
- [ ] **Proximity / Interaction Trigger (`Area3D`):** Detect when Saad approaches Hridy.
- [ ] **Resolution / Win Screen:**
  - Display victory / rescue message ("You found Hridy!").
  - Trigger celebratory or poignant dialogue.
  - Option to restart or return to title.

---

### Phase 4: Audio & Soundscapes ⚪
- [ ] **Procedural Footsteps:**
  - Leverage the existing `_animate()` footstep phase curve in `player.gd`.
  - Play alternating left/right pavement footstep audio at each step peak.
- [ ] **Flashlight Audio:**
  - Mechanical switch click sound on pressing `F`.
- [ ] **Ambient Soundscape:**
  - Continuous low wind howl and subtle city night hum with reverb.

---

### Phase 5: Interaction & Clues ⚪
- [ ] **Interactable Base Class / Area3D:** General component for objects player can interact with using key `E`.
- [ ] **Collectible Notes / Clues:**
  - Scattered pages giving hints to Hridy's hiding place.
  - Fullscreen/modal reading UI showing note text.
- [ ] **Flashlight Battery:**
  - Battery charge meter.
  - Collectible battery pickups scattered across the square.

---

### Phase 6: Menus & Final Polish ⚪
- [ ] **Pause Menu (`Esc`):** Resume, adjust mouse sensitivity, volume sliders, quit to desktop.
- [ ] **Main Menu / Title Screen:** Atmospheric start screen with start game and options.
- [ ] **Performance Pass:** Texture compression check and mesh LOD verification.
