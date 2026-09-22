# 🌆 Project Hollow Streets v2.0

![Godot 4](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godotengine&logoColor=white)
![Status](https://img.shields.io/badge/Status-Playable%20Build-success)
![No Git LFS Needed](https://img.shields.io/badge/Git%20LFS-Not%20Required-brightgreen)

Welcome to **Project Hollow Streets** — a 3D third-person atmospheric action/exploration game built in **Godot 4**.

---

## 🚀 Quick Start (Opening in Godot 4)

This repository is configured so that **the repository root is the Godot project root**. No Git LFS or external tools are required!

### Option A: Using Git Clone (Recommended)
```bash
git clone https://github.com/TalhaKun07-ipe/project-hollow-streets.git
```

### Option B: Download as ZIP
1. Click the green **Code** button on GitHub and select **Download ZIP**.
2. Extract the ZIP to your computer.

### Running the Project:
1. Open the **Godot 4 Project Manager** (Godot 4.0, 4.1, 4.2, 4.3, or 4.4+).
2. Click **Import** in the top-right corner.
3. Browse to and select the `project-hollow-streets` folder (or select `project.godot`).
4. Click **Import & Edit**.
5. Press **F5** (or click the Play icon in the top-right) to launch the game!

---

## 🎮 Controls

| Action | Key / Input |
| :--- | :--- |
| **Move Forward** | `W` |
| **Move Backward** | `S` |
| **Move Left** | `A` |
| **Move Right** | `D` |
| **Jump** | `Space` |
| **Toggle Flashlight / Torch** | `F` |
| **Orbit Camera** | `Mouse Movement` |
| **Camera Zoom** | `Mouse Wheel` |

---

## 📁 Project Structure

```text
project-hollow-streets/
├── project.godot               # Root Godot 4 engine configuration
├── icon.svg                    # Game project icon
├── scenes/                     # All scene files (.tscn)
│   ├── main.tscn               # Main level (street environment, lighting, ground)
│   ├── player.tscn             # CharacterBody3D player controller with camera and torch
│   ├── saad_model_animated.tscn# Animated 3D character mesh with AnimationPlayer
│   ├── buildings/              # Modular brick apartment, commercial tower, corner shop
│   └── props/                  # Streetlamps with volumetric lighting
├── scripts/                    # GDScript game logic (.gd)
│   ├── player.gd               # Physics movement, animations, audio & procedural torch
│   └── background_music.gd     # Seamless ambient soundtrack loop controller
├── assets/                     # 3D models, FBX animations, audio & character materials
│   ├── audio/                  # Footstep impact & mechanical flashlight switch audio
│   └── saad given assets/      # Continuous footsteps audio & background music track
├── textures/                   # Photorealistic PBR architectural & road textures
└── docs/                       # Complete project documentation suite
    ├── PROJECT_CONTEXT_FOR_AI.md # Master onboarding brief for AI models
    ├── FILE_MAP.md             # Complete file directory & dependency registry
    ├── ARCHITECTURE.md         # Scene trees, GDScript systems & node hierarchies
    ├── CHARACTER_ANIMATION_GUIDE.md # Rigging, Mixamo clips & animation blending
    ├── CODING_STANDARDS.md     # GDScript style guide & conventions
    ├── GAME_DESIGN.md          # Story premise, visual direction & design loop
    ├── ROADMAP.md              # Milestone tracker & upcoming features
    ├── DEVLOG.md               # Chronological updates & fix history
    └── README.md               # Documentation directory index
```

---

## 📚 Documentation & AI Onboarding

All project documentation is organized in the [`docs/`](docs/) directory:

* 🤖 **[Master AI Onboarding Brief](docs/PROJECT_CONTEXT_FOR_AI.md)**: **Hand this file to any AI assistant for instant, complete comprehension of the project!**
* 🗺️ **[File & Architecture Map](docs/FILE_MAP.md)**: Complete registry of what every single file does and its dependencies.
* 🏛️ **[Technical Architecture](docs/ARCHITECTURE.md)**: Scene trees, physics collision layers, and procedural math.
* 🏃 **[Character Animation Guide](docs/CHARACTER_ANIMATION_GUIDE.md)**: AnimationPlayer setup and bone rigging.
* 📜 **[Game Design Document](docs/GAME_DESIGN.md)**: Premise, aesthetic style, and worldbuilding.
* 📏 **[Coding Standards](docs/CODING_STANDARDS.md)**: Naming conventions and performance rules.
* 🗺️ **[Master Roadmap](docs/ROADMAP.md)**: Checklists and milestones.
* 📝 **[Developer Log](docs/DEVLOG.md)**: Changelog and record of all improvements.
