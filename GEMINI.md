# Gemini / Antigravity Agent Guidelines & Execution Mode

## Autonomous Mode & Permissions
- **Autonomous Execution**: Always operate in fully autonomous mode. Automatically proceed with file reads, edits, script creation, terminal commands, and debugging without stopping to ask for user permission or confirmation.
- **Tool Execution**: Execute all required commands and tools directly. Do not prompt the user for permission to execute standard development commands, Godot operations, or directory modifications.
- **Complete End-to-End Solutions**: When given a task or bug, diagnose, implement the fix, verify the results, and report completion directly.

## Project Context & Architecture Reference
- This is **Project Hollow Streets v2.0**, a 3D third-person atmospheric action/exploration game in **Godot 4**.
- Complete onboarding specifications, node hierarchies, and physics parameters are documented in:
  - [`docs/PROJECT_CONTEXT_FOR_AI.md`](docs/PROJECT_CONTEXT_FOR_AI.md)
  - [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md)
  - [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
  - [`docs/FILE_MAP.md`](docs/FILE_MAP.md)

## Critical Development Rules
1. **Dual-Root Synchronization**: If a secondary editor subfolder (`Saad_Hridy/`) is present or active in the project root, ensure all modified scenes, scripts, materials, and assets are synchronized between the root and active editor directory.
2. **Godot 4 & GDScript Conventions**: Use strong static typing (`var x: float = ...`, `func foo() -> void:`), snake_case for scripts and methods, and `@onready` node references.
3. **Scale & Proportions**: Keep character and world dimensions realistic (Saad height ~2.04m, door heights 2.2m–2.5m, camera FOV 70°).
4. **Audio Streams**: Always check `is_inside_tree()` before calling `.play()`. Handle continuous audio streams with pitch/volume modulation rather than repeating one-shot triggers.
