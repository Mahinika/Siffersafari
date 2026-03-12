// ignore_for_file: avoid_print

/// Generates Rive rig specification and blueprint for manual rigging.
///
/// Usage: dart run scripts/generate_rive_blueprint.dart
///
/// Reads: assets/characters/ville/config/ville_animation_spec.json
/// Outputs: artifacts/ville_rive_blueprint.json (detailed rigging guide)
library;

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🦴 Ville Rive Blueprint Generator');
  print('━' * 50);

  // Load animation spec
  final specFile =
      File('assets/characters/ville/config/ville_animation_spec.json');
  if (!specFile.existsSync()) {
    print('❌ Error: ville_animation_spec.json not found');
    exit(1);
  }

  final spec = jsonDecode(await specFile.readAsString());

  // Load visual spec for reference
  final visualSpecFile =
      File('assets/characters/ville/config/ville_visual_spec.json');
  final visualSpec = jsonDecode(await visualSpecFile.readAsString());

  final outputDir = Directory('artifacts');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final generator = RiveBlueprintGenerator(
    animationSpec: spec,
    visualSpec: visualSpec,
  );

  // Generate comprehensive blueprint
  final blueprint = generator.generateBlueprint();

  // Write JSON blueprint
  final blueprintFile = File('artifacts/ville_rive_blueprint.json');
  await blueprintFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(blueprint),
  );
  print('✅ Generated: ville_rive_blueprint.json');

  // Write human-readable guide
  final guideFile = File('artifacts/VILLE_RIVE_GUIDE.md');
  await guideFile.writeAsString(generator.generateMarkdownGuide());
  print('✅ Generated: VILLE_RIVE_GUIDE.md');

  print('━' * 50);
  print('🎉 Rive blueprint generated successfully!');
  print('');
  print('📖 Next steps:');
  print('   1. Open Rive Editor (https://rive.app)');
  print('   2. Import SVG parts from assets/characters/ville/svg/');
  print('   3. Follow blueprint in artifacts/ville_rive_blueprint.json');
  print('   4. Create bones, animations, and state machine as specified');
  print('   5. Export as assets/characters/ville/rive/ville_character.riv');
}

class RiveBlueprintGenerator {
  final Map<String, dynamic> animationSpec;
  final Map<String, dynamic> visualSpec;

  RiveBlueprintGenerator({
    required this.animationSpec,
    required this.visualSpec,
  });

  Map<String, dynamic> generateBlueprint() {
    return {
      'meta': {
        'version': '1.0',
        'character': animationSpec['character'],
        'description':
            "Complete Rive rigging blueprint for ${animationSpec['character']}",
        'target_artboard_name': 'Ville',
        'target_state_machine': 'VilleStateMachine',
      },
      'import_assets': _generateImportAssets(),
      'artboard': _generateArtboardStructure(),
      'bones': _generateBoneStructure(),
      'animations': _generateAnimationList(),
      'state_machine': _generateStateMachine(),
      'rigging_steps': _generateRiggingSteps(),
    };
  }

  Map<String, dynamic> _generateImportAssets() {
    return {
      'svg_parts': [
        {
          'file': 'assets/characters/ville/svg/ville_head.svg',
          'layer_name': 'head',
        },
        {
          'file': 'assets/characters/ville/svg/ville_eyes_open.svg',
          'layer_name': 'eyes_open',
        },
        {
          'file': 'assets/characters/ville/svg/ville_eyes_closed.svg',
          'layer_name': 'eyes_closed',
        },
        {
          'file': 'assets/characters/ville/svg/ville_mouth_smile.svg',
          'layer_name': 'mouth_smile',
        },
        {
          'file': 'assets/characters/ville/svg/ville_mouth_sad.svg',
          'layer_name': 'mouth_sad',
        },
        {
          'file': 'assets/characters/ville/svg/ville_mouth_neutral.svg',
          'layer_name': 'mouth_neutral',
        },
        {
          'file': 'assets/characters/ville/svg/ville_body.svg',
          'layer_name': 'body',
        },
        {
          'file': 'assets/characters/ville/svg/ville_arm_left.svg',
          'layer_name': 'arm_left',
        },
        {
          'file': 'assets/characters/ville/svg/ville_arm_right.svg',
          'layer_name': 'arm_right',
        },
        {
          'file': 'assets/characters/ville/svg/ville_leg_left.svg',
          'layer_name': 'leg_left',
        },
        {
          'file': 'assets/characters/ville/svg/ville_leg_right.svg',
          'layer_name': 'leg_right',
        },
        {
          'file': 'assets/characters/ville/svg/ville_antennas.svg',
          'layer_name': 'antennas',
        },
      ],
      'import_order': [
        'body (bottom layer)',
        'legs',
        'arms',
        'head',
        'eyes',
        'mouth',
        'antennas (top layer)',
      ],
    };
  }

  Map<String, dynamic> _generateArtboardStructure() {
    return {
      'name': 'Ville',
      'width': 400,
      'height': 600,
      'origin': {'x': 200, 'y': 500},
      'layer_hierarchy': [
        {'name': 'body', 'parent': null, 'sort_order': 0},
        {'name': 'leg_left', 'parent': 'body', 'sort_order': 1},
        {'name': 'leg_right', 'parent': 'body', 'sort_order': 2},
        {'name': 'arm_left', 'parent': 'body', 'sort_order': 3},
        {'name': 'arm_right', 'parent': 'body', 'sort_order': 4},
        {'name': 'head', 'parent': 'body', 'sort_order': 5},
        {'name': 'eyes_layer', 'parent': 'head', 'sort_order': 6},
        {'name': 'mouth_layer', 'parent': 'head', 'sort_order': 7},
        {'name': 'antennas', 'parent': 'head', 'sort_order': 8},
      ],
    };
  }

  Map<String, dynamic> _generateBoneStructure() {
    final rig = animationSpec['rig'] as Map<String, dynamic>;
    final bones = rig['bones'] as List<dynamic>;

    return {
      'bones': bones.map((boneName) {
        return {
          'name': boneName,
          'parent': _getBoneParent(boneName as String),
          'position': _getBonePosition(boneName),
          'bind_mesh': _getBoneMesh(boneName),
        };
      }).toList(),
      'constraints': (rig['constraints'] as List<dynamic>)
          .map((c) => c.toString())
          .toList(),
    };
  }

  Map<String, dynamic> _generateAnimationList() {
    final animations = animationSpec['animations'] as Map<String, dynamic>;
    final allAnimations = <Map<String, dynamic>>[];

    animations.forEach((category, animList) {
      for (final animName in animList as List<dynamic>) {
        allAnimations.add({
          'name': animName,
          'category': category,
          'duration_seconds': _getAnimationDuration(animName as String),
          'keyframes': _getAnimationKeyframes(animName),
        });
      }
    });

    return {
      'total': allAnimations.length,
      'animations': allAnimations,
    };
  }

  Map<String, dynamic> _generateStateMachine() {
    final states = animationSpec['states'] as Map<String, dynamic>;
    final stateList = states['list'] as List<dynamic>;
    final transitions = states['transitions'] as List<dynamic>;

    return {
      'name': 'VilleStateMachine',
      'initial_state': states['initial'],
      'inputs': [
        {'name': 'answer_correct', 'type': 'Trigger'},
        {'name': 'answer_wrong', 'type': 'Trigger'},
        {'name': 'user_tap', 'type': 'Trigger'},
        {'name': 'screen_change', 'type': 'Trigger'},
      ],
      'states': stateList.map((stateName) {
        return {
          'name': stateName,
          'animation': _mapStateToAnimation(stateName as String),
          'loop': stateName == 'idle',
        };
      }).toList(),
      'transitions': transitions.map((t) {
        final transition = t as Map<String, dynamic>;
        return {
          'from': transition['from'],
          'to': transition['to'],
          'trigger': transition['trigger'],
        };
      }).toList(),
    };
  }

  List<Map<String, dynamic>> _generateRiggingSteps() {
    return [
      {
        'step': 1,
        'title': 'Import SVG Assets',
        'instructions':
            'Import all 12 SVG files from assets/characters/ville/svg/ into Rive. Keep layer names matching file names.',
      },
      {
        'step': 2,
        'title': 'Create Artboard',
        'instructions':
            "Create artboard named 'Ville' (400×600px). Arrange layers in hierarchy: body → legs/arms → head → eyes/mouth → antennas.",
      },
      {
        'step': 3,
        'title': 'Add Bones',
        'instructions':
            'Create 9 bones: root (at feet), spine (center body), head (top of neck), arm_left, arm_right, leg_left, leg_right, antenna_left, antenna_right. Parent correctly.',
      },
      {
        'step': 4,
        'title': 'Bind Meshes',
        'instructions':
            "Use Rive's Weight Painting tool to bind each SVG mesh to appropriate bones. Arms → arm bones, legs → leg bones, head → head bone, etc.",
      },
      {
        'step': 5,
        'title': 'Create Animations',
        'instructions':
            'Create all animations from blueprint. Start with idle, idle_blink. Use timeline to keyframe bone rotations and positions.',
      },
      {
        'step': 6,
        'title': 'Build State Machine',
        'instructions':
            "Create state machine 'VilleStateMachine'. Add 4 trigger inputs: answer_correct, answer_wrong, user_tap, screen_change. Wire states per blueprint transitions.",
      },
      {
        'step': 7,
        'title': 'Test & Export',
        'instructions':
            'Test all triggers in Rive preview. Export as .riv file to assets/characters/ville/rive/ville_character.riv',
      },
    ];
  }

  // Helper methods
  String? _getBoneParent(String boneName) {
    final parentMap = {
      'root': null,
      'spine': 'root',
      'head': 'spine',
      'arm_left': 'spine',
      'arm_right': 'spine',
      'leg_left': 'root',
      'leg_right': 'root',
      'antenna_left': 'head',
      'antenna_right': 'head',
    };
    return parentMap[boneName];
  }

  Map<String, double> _getBonePosition(String boneName) {
    final positions = {
      'root': {'x': 200.0, 'y': 500.0},
      'spine': {'x': 200.0, 'y': 350.0},
      'head': {'x': 200.0, 'y': 150.0},
      'arm_left': {'x': 140.0, 'y': 320.0},
      'arm_right': {'x': 260.0, 'y': 320.0},
      'leg_left': {'x': 170.0, 'y': 480.0},
      'leg_right': {'x': 230.0, 'y': 480.0},
      'antenna_left': {'x': 160.0, 'y': 80.0},
      'antenna_right': {'x': 240.0, 'y': 80.0},
    };
    return positions[boneName] ?? {'x': 200.0, 'y': 300.0};
  }

  String _getBoneMesh(String boneName) {
    final meshMap = {
      'root': 'body',
      'spine': 'body',
      'head': 'head',
      'arm_left': 'arm_left',
      'arm_right': 'arm_right',
      'leg_left': 'leg_left',
      'leg_right': 'leg_right',
      'antenna_left': 'antennas',
      'antenna_right': 'antennas',
    };
    return meshMap[boneName] ?? 'body';
  }

  double _getAnimationDuration(String animName) {
    if (animName.contains('blink')) return 0.3;
    if (animName.contains('tap') || animName.contains('react')) return 0.4;
    if (animName.contains('celebrate')) return 1.2;
    if (animName.contains('enter') || animName.contains('exit')) return 0.6;
    if (animName.contains('jump')) return 0.8;
    return 1.0;
  }

  List<String> _getAnimationKeyframes(String animName) {
    final keyframeMap = {
      'idle': ['breathing (scale 1.0 → 1.02)', 'antenna sway (±5°)'],
      'idle_blink': ['eyes: open → closed → open', 'duration: 0.2s'],
      'celebrate_small': ['jump 20px', 'arms up', 'smile visible'],
      'celebrate_big': [
        'jump 50px',
        'arms wave',
        'antennas spring',
        'smile big',
      ],
      'sad': ['head tilt down 15°', 'arms down', 'sad mouth visible'],
      'confused': ['head tilt left/right', 'eyes narrow', 'neutral mouth'],
      'tap_react': ['scale 1.1 → 1.0', 'slight rotate', 'eyes wide'],
      'enter_screen': ['position: x -100 → 200', 'wave hand'],
      'exit_screen': ['position: x 200 → 500', 'wave goodbye'],
    };
    return keyframeMap[animName] ?? ['define keyframes for $animName'];
  }

  String _mapStateToAnimation(String stateName) {
    final mappings = {
      'idle': 'idle',
      'idle_blink': 'idle_blink',
      'happy': 'celebrate_small',
      'very_happy': 'celebrate_big',
      'sad': 'sad',
      'confused': 'confused',
      'react_tap': 'tap_react',
      'enter': 'enter_screen',
      'exit': 'exit_screen',
    };
    return mappings[stateName] ?? 'idle';
  }

  String generateMarkdownGuide() {
    return '''# Ville Rive Rigging Guide

Generated: ${DateTime.now().toIso8601String()}

## Overview
This guide provides step-by-step instructions for rigging Ville character in Rive Editor.

## Prerequisites
- Rive Editor (https://rive.app)
- All SVG parts generated in `assets/characters/ville/svg/`

## Step 1: Import Assets
Import these SVG files into Rive (File → Import):
${_generateImportAssets()['svg_parts'].map((a) => '- ${a['file']}').join('\n')}

## Step 2: Create Artboard
- Name: **Ville**
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
${_generateBoneStructure()['bones'].map((b) => '- **${b['name']}** → parent: ${b['parent'] ?? 'null'} → binds: ${b['bind_mesh']}').join('\n')}

## Step 4: Weight Paint
Use Rive's Weight Painting tool:
- Select bone → Select mesh → Paint weights
- Arms: full weight to respective arm bones
- Legs: full weight to respective leg bones
- Head: full weight to head bone
- Body: gradient from spine to root
- Antennas: spring-like weights from head

## Step 5: Create Animations
${_generateAnimationList()['animations'].map(
              (a) => '''
### ${a['name']} (${a['duration_seconds']}s)
Category: ${a['category']}
Keyframes:
${(a['keyframes'] as List).map((k) => '  - $k').join('\n')}
''',
            ).join('\n')}

## Step 6: Build State Machine
Name: **VilleStateMachine**

### Inputs (Triggers)
- answer_correct
- answer_wrong
- user_tap
- screen_change

### States
${_generateStateMachine()['states'].map((s) => '- **${s['name']}** → plays: ${s['animation']} ${s['loop'] ? '(loop)' : '(once)'}').join('\n')}

### Transitions
${_generateStateMachine()['transitions'].map((t) => '- ${t['from']} → ${t['to']} [trigger: ${t['trigger']}]').join('\n')}

## Step 7: Export
1. Test all triggers in Rive preview
2. File → Export → .riv
3. Save as: `assets/characters/ville/rive/ville_character.riv`
4. Verify artboard name = "Ville" and state machine name = "VilleStateMachine"

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
- Refer to `ville_rive_blueprint.json` for detailed technical spec
- Colors and proportions from `ville_visual_spec.json`
- Animation timing can be adjusted in Rive timeline
''';
  }
}
