// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() async {
  // Sprite names based on grid position (6 cols x 4 rows)
  final spriteNames = [
    // Row 1
    ['idle', 'walk_left', 'walk_right', 'walk_up', 'sprite_04', 'sprite_05'],
    // Row 2
    ['run_left', 'run_right', 'jump_up', 'jump_down', 'sprite_14', 'sprite_15'],
    // Row 3
    ['crouch', 'attack', 'hurt', 'die', 'sitting', 'sprite_25'],
    // Row 4
    ['sleep', 'wave', 'digging', 'sit', 'sprite_34', 'sprite_35'],
  ];

  final inputPath = 'spritesheet.png';
  final outputDir = 'assets/images/characters/ville';

  // Create output directory
  final outDir = Directory(outputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
    print('Created output directory: $outputDir');
  }

  // Load sprite sheet
  final imageData = File(inputPath).readAsBytesSync();
  final spriteSheet = img.decodeImage(imageData);

  if (spriteSheet == null) {
    print('Failed to load sprite sheet');
    return;
  }

  print('Sprite sheet loaded: ${spriteSheet.width}x${spriteSheet.height}');

  // Calculate sprite dimensions
  final cols = 6;
  final rows = 4;
  final spriteWidth = spriteSheet.width ~/ cols;
  final spriteHeight = spriteSheet.height ~/ rows;

  print('Sprite dimensions: ${spriteWidth}x$spriteHeight');
  print('Extracting ${cols * rows} sprites...\n');

  // Extract sprites
  int count = 0;
  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      final x = col * spriteWidth;
      final y = row * spriteHeight;

      // Crop sprite
      final sprite = img.copyCrop(
        spriteSheet,
        x: x,
        y: y,
        width: spriteWidth,
        height: spriteHeight,
      );

      // Save sprite
      final name = spriteNames[row][col];
      final outputPath = p.join(outputDir, '$name.png');
      File(outputPath).writeAsBytesSync(img.encodePng(sprite));

      print('✓ Extracted: $name.png');
      count++;
    }
  }

  print('\nCompleted! Extracted $count sprites to $outputDir');
}
