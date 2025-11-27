# CONNECT8
*A small Verilog game project on the DE1-SoC board, inspired by [Block-Blast](https://www.hungrystudio.com/games)*  
by **Alan He** and [**Harry Zhang**](https://github.com/po8onthetrack)  for ECE241 @ University of Toronto, Supervised by [**Prof. Jason Anderson**](https://janders.eecg.utoronto.ca/)

_Last updated: 2025-11-26_

---

## Overview
CONNECT8 is a Block-Blast-style puzzle game fully implemented in Verilog and running on the **Intel DE1-SoC (Cyclone V)** FPGA.

The design uses:
- **VGA (640×480)** for video output  
- the on-board **PS/2 port** for keyboard input  
- a purely hardware **game logic engine** (no CPU or embedded software)

All gameplay, state updates, and rendering decisions are handled in synchronous RTL.

---

## System Architecture

The project is organized into four major subsystems:

### 1. PS/2 Input
- Uses a vendor-supplied PS/2 core for low-level protocol handling and parity checking  
- Custom keyboard adapter translates scancodes into game control signals  
- Produces one-cycle, debounced control pulses:
  - `move_left`, `move_right`, `move_up`, `move_down`
  - `sel1`, `sel2`, `sel3`
  - `place_block`, `reset`
- Edge detection prevents a long key press from generating multiple moves in one frame

### 2. Block Generator
- LFSR-based pseudo-random generator for piece selection  
- Shape library stored as 64-bit constants (each as an 8×8 mask)  
- Generates three new blocks when the tray is empty (triggered by `generate_new`)  
- Design intentionally avoids runtime rotation; orientations are chosen offline to simplify hardware  
- Gated update logic ensures:
  - LFSR only advances when needed  
  - no all-zero (invalid) blocks are ever output

### 3. Game Logic Core
Encapsulates the entire game state and rule set:

- Maintains:
  - current board (`game_grid`)  
  - three preview blocks and their anchor positions  
  - current score and game-over flag  
- On a placement:
  - checks placement legality  
  - merges the block into the board  
  - detects full rows and columns  
  - computes scoring, including combined row/column clears  
- Uses a snapshot-before-clear approach to avoid race conditions between update and detection  
- Performs a full-board, all-block scan to determine if any valid move remains before asserting `game_over`

### 4. VGA Output
- Uses a 640×480@60 Hz VGA timing module:
  - Generates `(x, y)` pixel coordinates, HS/VS, and blanking signals  
- Custom VGA controller:
  - Maps `(x, y)` to board coordinates and a linear index into `game_grid`  
  - Renders a 400×400 board region centered on the screen  
  - Applies a fixed color priority:
    1. placed blocks  
    2. preview blocks  
    3. grid lines  
    4. background  
- Multiple visual layers are implemented in hardware:
  - title, background, and game-over images are stored in ROMs  
  - assets are generated via PNG → MIF conversion  
  - the active layer is selected based on the game state

