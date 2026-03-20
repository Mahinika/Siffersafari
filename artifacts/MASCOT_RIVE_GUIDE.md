# Mascot Rive Rigging Guide

Generated: 2026-03-20T21:37:17.835321

## Overview
This guide provides step-by-step instructions for rigging the mascot character in Rive Editor.

## Prerequisites
- Rive Editor (https://rive.app)
- All SVG parts generated in `assets/characters/mascot/svg/`

## Step 1: Import Assets
Import these SVG files into Rive (File → Import):
- assets/characters/mascot/svg/mascot_head.svg
- assets/characters/mascot/svg/mascot_eyes_open.svg
- assets/characters/mascot/svg/mascot_eyes_closed.svg
- assets/characters/mascot/svg/mascot_mouth_smile.svg
- assets/characters/mascot/svg/mascot_mouth_sad.svg
- assets/characters/mascot/svg/mascot_mouth_neutral.svg
- assets/characters/mascot/svg/mascot_body.svg
- assets/characters/mascot/svg/mascot_arm_left.svg
- assets/characters/mascot/svg/mascot_arm_right.svg
- assets/characters/mascot/svg/mascot_leg_left.svg
- assets/characters/mascot/svg/mascot_leg_right.svg
- assets/characters/mascot/svg/mascot_antennas.svg

## Step 2: Create Artboard
- Name: **Mascot**
- Size: 400×600 px
- Arrange layers as:
  - body (bottom)
  - legs (leg_left, leg_right)
  - arms (arm_left, arm_right)
  - head
  - eyes (create blend between open/closed)
  - mouth (create blend between smile/sad/neutral)
  - antennas (top)

## Step 3: Add Bones
Create these bones in parent-child hierarchy:
- **root** → parent: null → binds: body
- **spine** → parent: root → binds: body
- **head** → parent: spine → binds: head
- **arm_left** → parent: spine → binds: arm_left
- **arm_right** → parent: spine → binds: arm_right
- **leg_left** → parent: root → binds: leg_left
- **leg_right** → parent: root → binds: leg_right
- **antenna_left** → parent: head → binds: antennas
- **antenna_right** → parent: head → binds: antennas

## Step 4: Weight Paint
Use Rive's Weight Painting tool:
- Select bone → Select mesh → Paint weights
- Arms: full weight to respective arm bones
- Legs: full weight to respective leg bones
- Head: full weight to head bone
- Body: gradient from spine to root
- Antennas: spring-like weights from head

## Step 5: Create Animations
### idle (1.0s)
Category: base
Keyframes:
  - breathing (scale 1.0 → 1.02)
  - antenna sway (±5°)

### idle_blink (0.3s)
Category: base
Keyframes:
  - eyes: open → closed → open
  - duration: 0.2s

### idle_look_left (1.0s)
Category: base
Keyframes:
  - define keyframes for idle_look_left

### idle_look_right (1.0s)
Category: base
Keyframes:
  - define keyframes for idle_look_right

### celebrate_small (1.2s)
Category: positive
Keyframes:
  - jump 20px
  - arms up
  - smile visible

### celebrate_big (1.2s)
Category: positive
Keyframes:
  - jump 50px
  - arms wave
  - antennas spring
  - smile big

### thumbs_up (1.0s)
Category: positive
Keyframes:
  - define keyframes for thumbs_up

### jump_happy (0.8s)
Category: positive
Keyframes:
  - define keyframes for jump_happy

### sad (1.0s)
Category: negative
Keyframes:
  - head tilt down 15°
  - arms down
  - sad mouth visible

### confused (1.0s)
Category: negative
Keyframes:
  - head tilt left/right
  - eyes narrow
  - neutral mouth

### shake_head (1.0s)
Category: negative
Keyframes:
  - define keyframes for shake_head

### tap_react (0.4s)
Category: interactive
Keyframes:
  - scale 1.1 → 1.0
  - slight rotate
  - eyes wide

### enter_screen (0.6s)
Category: interactive
Keyframes:
  - position: x -100 → 200
  - wave hand

### exit_screen (0.6s)
Category: interactive
Keyframes:
  - position: x 200 → 500
  - wave goodbye


## Step 6: Build State Machine
Name: **MascotStateMachine**

### Inputs (Triggers)
- answer_correct
- answer_wrong
- user_tap
- screen_change

### States
- **idle** → plays: idle (loop)
- **idle_blink** → plays: idle_blink (once)
- **happy** → plays: celebrate_small (once)
- **very_happy** → plays: celebrate_big (once)
- **sad** → plays: sad (once)
- **confused** → plays: confused (once)
- **react_tap** → plays: tap_react (once)
- **enter** → plays: enter_screen (once)
- **exit** → plays: exit_screen (once)

### Transitions
- idle → happy [trigger: answer_correct]
- idle → sad [trigger: answer_wrong]
- happy → idle [trigger: animation_done]
- sad → idle [trigger: animation_done]
- idle → react_tap [trigger: user_tap]
- react_tap → idle [trigger: animation_done]
- enter → idle [trigger: animation_done]
- idle → exit [trigger: screen_change]

## Step 7: Export
1. Test all triggers in Rive preview
2. File → Export → .riv
3. Save as: `assets/characters/mascot/rive/mascot_character.riv`
4. Verify artboard name = "Mascot" and state machine name = "MascotStateMachine"

## Testing Checklist
- [ ] Idle animation loops smoothly
- [ ] Blink plays correctly
- [ ] answer_correct trigger → happy animation
- [ ] answer_wrong trigger → sad animation
- [ ] user_tap trigger → react animation
- [ ] screen_change trigger → exit animation
- [ ] All animations return to idle
- [ ] No mesh tearing or weird deformations

## Notes
- Refer to `mascot_rive_blueprint.json` for detailed technical spec
- Colors and proportions from `mascot_visual_spec.json`
- Animation timing can be adjusted in Rive timeline
