# Game Design Document (GDD)

*Project Hollow Streets v2.0 (Saad & Hridy)*

---

## 1. High Concept & Vision Statement

**"Project Hollow Streets"** is an atmospheric third-person exploration mystery. The player steps into the shoes of **Saad**, wandering through the quiet, eerie, fog-draped streets of an abandoned or late-night city square. Guided only by the warm glow of his handheld torch and distant cyan lampposts, Saad's singular, driving mission is to navigate the shadows and find **Hridy**.

* **Tone:** Eerie, contemplative, suspenseful, yet intimate.
* **Inspirations:** *Kingdom Hearts* (movement feel & camera perspective), *Alan Wake* (flashlight contrast and night shadows), *Silent Hill* (fog and psychological atmosphere).
* **Target Audience:** Adventure, atmospheric exploration, and narrative-driven gamers.

---

## 2. Narrative & World Premise

### 2.1 The Setting: "The Hollow Streets"
The game takes place in a closed city block surrounded by towering, silent buildings. Some windows glow with pale, distant blue light, hinting at unseen life, while others remain pitch black. Time seems frozen at 2:00 AM; cold moonlight casts long, sharp shadows across the cracked asphalt.

### 2.2 The Characters
* **Saad (The Protagonist):** Equipped with an overcoat and a heavy torch. He is determined and cautious.
* **Hridy (The Objective):** Currently missing or waiting at an undisclosed location across the square—hidden down an alley, behind a barricade, or atop a fire escape.

---

## 3. Core Gameplay Loop

```
      ┌──────────────────────────────┐
      │   Spawn in Dark City Square  │
      └──────────────┬───────────────┘
                     │
                     ▼
      ┌──────────────────────────────┐
      │  Explore & Search with Torch │
      └──────────────┬───────────────┘
                     │
                     ▼
      ┌──────────────────────────────┐
      │  Discover Environmental Cues │ ◄── (Notes, glowing traces, sounds)
      └──────────────┬───────────────┘
                     │
                     ▼
      ┌──────────────────────────────┐
      │     Locate & Reach Hridy     │
      └──────────────┬───────────────┘
                     │
                     ▼
      ┌──────────────────────────────┐
      │ Victory Cutscene / Dialog UI │
      └──────────────────────────────┘
```

1. **Orientation:** The player assesses their surroundings in the dimly lit square.
2. **Investigation:** Using the flashlight (`F`) to illuminate dark corners, alleyways, and building alcoves.
3. **Clue Gathering:** Inspecting environmental clues (e.g., dropped personal items, written notes, flickering lights).
4. **Resolution:** Finding Hridy, triggering an interaction sequence that completes the objective.

---

## 4. Mechanics & Player Abilities

### 4.1 Locomotion & Physics
* **Walk & Sprint:** Standard walk speed ($4.5\text{ m/s}$) for careful inspection; sprint speed ($7.5\text{ m/s}$) for crossing open streets quickly.
* **Jump:** Allows climbing curbs, small obstacles, or debris ($6.2\text{ m/s}$ jump impulse).
* **Procedural Animation Weight:** The movement incorporates simulated footfalls, dynamic turn banking, breathing, and landing squash to give the character physical presence in the world.

### 4.2 The Torch (Flashlight)
* **Toggle (`F`):** Can be turned on/off instantly.
* **Lighting Dynamics:** A directional cone ($72\text{m}$ range, $44^\circ$ cone angle) casting real-time shadows. In thick fog, the torch creates a visible volumetric light beam.
* *(Planned)* **Battery Meter:** Flashlight battery slowly drains over time and requires collecting replacement batteries scattered in the environment.

### 4.3 Interaction System (Planned)
* **Context Prompt:** Approaching items, doors, or NPCs displays an `[E] Interact` indicator.
* **Clue Inspection:** Inspecting a note brings up a readable HUD overlay with narrative text or clues to Hridy's whereabouts.

---

## 5. Visual & Art Direction

### 5.1 Color Palette
* **Ambient Darkness:** Midnight Navy (`#0d0d14` / `Color(0.05, 0.05, 0.08)`).
* **Moonlight:** Desaturated Ice Blue (`Color(0.50, 0.57, 0.84)`).
* **Streetlights:** Cyan / Aqua Glow (`Color(0.58, 0.85, 0.95)`).
* **Torch Beam:** Warm Incandescent Amber (`Color(1.0, 0.85, 0.55)`).
* **Lit Windows:** Electric Blue (`Color(0.20, 0.26, 0.63)`).

### 5.2 Environmental Aesthetics
* **Atmospheric Volumetric Fog:** Drifting night mist hanging close to the asphalt and scattering streetlight cones.
* **Urban Detritus:** Barricades, dumpsters, lampposts, trash cans, chain-link fences, and street signs giving texture to the city.
* **Contrast:** Heavy chiaroscuro lighting—deep black shadows contrasted against sharp beams of light.

---

## 6. Audio Design Direction

Audio is essential for selling the mood of an empty city at night:

| Sound Category | Description | Implementation Target |
| :--- | :--- | :--- |
| **Footsteps** | Rhythmic, muffled pavement steps synced to procedural footfall beats. | `AudioStreamPlayer3D` triggered in `_animate()` |
| **Flashlight Click** | Crisp mechanical switch click when toggling on/off. | One-shot on `toggle_torch` |
| **Wind & Ambiance** | Low howling wind, distant sirens, humming electric wires. | Looping `AudioStreamPlayer` bus: "Ambiance" |
| **Clue / Discovery** | Subtle, eerie chime or soft piano note upon finding a clue or Hridy. | UI Audio feedback |
