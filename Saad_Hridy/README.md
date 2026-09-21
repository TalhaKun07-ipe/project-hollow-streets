# Project Hollow Streets v2.0 (Saad & Hridy)

An atmospheric third-person mystery/exploration game built with **Godot Engine 4 (v4.7.2 Forward+)**.

---

## 📖 Overview

The player controls **Saad**, navigating through an eerie, desolate city block at night illuminated only by faint streetlamps and a personal flashlight, searching for **Hridy**.

This repository contains the complete Godot 4 project, assets, custom procedural animation mechanics, and development documentation.

---

## 📚 Documentation Index

To ensure seamless collaboration between developers, contributors, and AI assistants, comprehensive technical documentation is maintained in the [`docs/`](docs/) directory:

| Document | Description |
| :--- | :--- |
| **[Architecture & Systems](docs/ARCHITECTURE.md)** | Deep technical dive into scenes, node trees, GDScript systems, physics, and procedural animation math. |
| **[Game Design Document](docs/GAME_DESIGN.md)** | Narrative premise, player mechanics, atmosphere, aesthetic vision, and audio design. |
| **[Coding & Asset Standards](docs/CODING_STANDARDS.md)** | GDScript style guidelines, collision layer conventions, node organization, and texture/asset optimization rules. |
| **[Character Animation Guide](docs/CHARACTER_ANIMATION_GUIDE.md)** | Step-by-step blueprints for 3D Mixamo rigging vs 2.5D sprite sheets, grid specs, and AnimationTree design. |
| **[Master Roadmap](docs/ROADMAP.md)** | Phased milestones, backlog of features, ideas, and planned improvements. |
| **[Developer Log](docs/DEVLOG.md)** | Chronological log of changes, bug fixes, features added, and work sessions. |

---

## 🚀 Getting Started & How to Run

### Prerequisites
* **Godot Engine 4.x** (Configured with Godot 4.7.x, Forward+ renderer).
* Executable available locally: `Godot_v4.7.2-stable_win64.exe` (or Godot 4 console).

### Launching the Game
1. **Using Godot Editor:**
   * Open Godot Engine.
   * Click **Import** and select `Saad_Hridy/project.godot`.
   * Press **F5** (or click the Play button in the top right).
2. **Using Command Line:**
   ```powershell
   & "C:\Users\USER\Downloads\Godot_v4.7.2-stable_win64_console.exe" --path "c:\Users\USER\Desktop\saad game\Saad_Hridy"
   ```

---

## 🎮 Controls

| Action | Input | Description |
| :--- | :--- | :--- |
| **Move** | `W` / `A` / `S` / `D` | Walk in camera-relative direction |
| **Sprint** | `Shift` (Hold) | Increases movement speed from 4.5 to 7.5 m/s |
| **Jump** | `Space` | Jump into the air |
| **Camera** | `Mouse Motion` | Third-person orbit camera |
| **Toggle Flashlight** | `F` | Turn torch SpotLight on / off |
| **Mouse Unlock** | `Esc` / `ui_cancel` | Toggle mouse capture between captured and visible |

---

## 📁 Project Structure

```
Saad_Hridy/
├── project.godot                # Godot 4 project configuration & input maps
├── icon.svg                     # Project icon
├── docs/                        # Complete technical & design documentation
│   ├── ARCHITECTURE.md          # Scene graphs, scripts, and math breakdown
│   ├── GAME_DESIGN.md           # Narrative, mechanics, and design vision
│   ├── CODING_STANDARDS.md      # Conventions and guidelines
│   ├── ROADMAP.md               # Milestones and upcoming tasks
│   └── DEVLOG.md                # Development history and changelog
├── scenes/
│   ├── main.tscn                # Main level scene (city square, lighting, buildings, UI)
│   └── player.tscn              # Player scene (CharacterBody3D, Camera, Torch)
├── scripts/
│   └── player.gd                # Player physics, camera orbit, procedural animations
├── assets/
│   ├── saad_model.glb           # 3D scan mesh of Saad
│   └── white_mesh.glb           # Base reference mesh
├── textures/                    # 4K terrain textures (diffuse, normal, roughness)
└── texture/textures/            # 4K rock wall building textures
```
