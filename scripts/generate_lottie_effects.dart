// ignore_for_file: avoid_print

/// Generates Lottie UI effect animations.
///
/// Usage: dart run scripts/generate_lottie_effects.dart
///
/// Outputs: assets/ui/lottie/*.json (4 files)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main() async {
  print('✨ Lottie Effect Generator');
  print('━' * 50);

  final outputDir = Directory('assets/ui/lottie');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final generator = LottieEffectGenerator();

  final effects = {
    'confetti': generator.generateConfetti(),
    'stars': generator.generateStars(),
    'success_pulse': generator.generateSuccessPulse(),
    'error_shake': generator.generateErrorShake(),
    'ville_walk': generator.generateVilleWalk(),
  };

  for (final entry in effects.entries) {
    final file = File('${outputDir.path}/${entry.key}.json');
    await file.writeAsString(jsonEncode(entry.value));
    print('✅ Generated: ${entry.key}.json');
  }

  print('━' * 50);
  print('🎉 Generated ${effects.length} Lottie effects successfully!');
}

class LottieEffectGenerator {
  /// Generates confetti celebration animation
  Map<String, dynamic> generateConfetti() {
    final particles = <Map<String, dynamic>>[];
    final random = math.Random(42);

    // Generate 20 confetti particles
    for (int i = 0; i < 20; i++) {
      final startX = 200 + random.nextDouble() * 200 - 100;
      final startY = -50 - random.nextDouble() * 100;
      final endY = 600 + random.nextDouble() * 100;
      final rotation = random.nextDouble() * 720 - 360;
      final color = _randomConfettiColor(random);
      final size = 8 + random.nextDouble() * 12;

      particles.add({
        'ty': 4, // Shape layer
        'nm': 'Confetti $i',
        'sr': 1,
        'ks': {
          'o': {'a': 0, 'k': 100},
          'r': {
            'a': 1,
            'k': [
              {
                'i': {
                  'x': [0.42],
                  'y': [1],
                },
                'o': {
                  'x': [0.58],
                  'y': [0],
                },
                't': 0,
                's': [0],
              },
              {
                't': 90,
                's': [rotation],
              },
            ],
          },
          'p': {
            'a': 1,
            'k': [
              {
                'i': {'x': 0.42, 'y': 1},
                'o': {'x': 0.58, 'y': 0},
                't': 0,
                's': [startX, startY],
              },
              {
                't': 90,
                's': [startX + (random.nextDouble() * 100 - 50), endY],
              },
            ],
          },
          'a': {
            'a': 0,
            'k': [0, 0],
          },
          's': {
            'a': 0,
            'k': [100, 100],
          },
        },
        'shapes': [
          {
            'ty': 'rc', // Rectangle
            'nm': 'Rectangle',
            'd': 1,
            's': {
              'a': 0,
              'k': [size, size * 2],
            },
            'r': {'a': 0, 'k': 2},
          },
          {
            'ty': 'fl', // Fill
            'c': {'a': 0, 'k': color},
            'o': {'a': 0, 'k': 100},
          }
        ],
      });
    }

    return {
      'v': '5.7.4',
      'fr': 30,
      'ip': 0,
      'op': 90,
      'w': 400,
      'h': 600,
      'nm': 'Confetti',
      'ddd': 0,
      'assets': [],
      'layers': particles,
    };
  }

  /// Generates twinkling stars animation
  Map<String, dynamic> generateStars() {
    final stars = <Map<String, dynamic>>[];
    final random = math.Random(123);

    // Generate 8 stars
    for (int i = 0; i < 8; i++) {
      final x = 50 + random.nextDouble() * 300;
      final y = 50 + random.nextDouble() * 300;
      final delay = i * 8;
      final size = 20 + random.nextDouble() * 30;

      stars.add({
        'ty': 4,
        'nm': 'Star $i',
        'sr': 1,
        'st': delay.toDouble(),
        'ks': {
          'o': {
            'a': 1,
            'k': [
              {
                't': delay,
                's': [0],
              },
              {
                't': delay + 10,
                's': [100],
              },
              {
                't': delay + 30,
                's': [100],
              },
              {
                't': delay + 40,
                's': [0],
              },
            ],
          },
          'r': {'a': 0, 'k': 0},
          'p': {
            'a': 0,
            'k': [x, y],
          },
          'a': {
            'a': 0,
            'k': [0, 0],
          },
          's': {
            'a': 1,
            'k': [
              {
                't': delay,
                's': [0, 0],
              },
              {
                't': delay + 10,
                's': [120, 120],
              },
              {
                't': delay + 30,
                's': [120, 120],
              },
              {
                't': delay + 40,
                's': [0, 0],
              },
            ],
          },
        },
        'shapes': [
          _createStarPath(size),
          {
            'ty': 'fl',
            'c': {
              'a': 0,
              'k': [1, 0.84, 0, 1],
            }, // Gold
            'o': {'a': 0, 'k': 100},
          }
        ],
      });
    }

    return {
      'v': '5.7.4',
      'fr': 30,
      'ip': 0,
      'op': 120,
      'w': 400,
      'h': 400,
      'nm': 'Stars',
      'ddd': 0,
      'assets': [],
      'layers': stars,
    };
  }

  /// Generates success pulse animation
  Map<String, dynamic> generateSuccessPulse() {
    return {
      'v': '5.7.4',
      'fr': 30,
      'ip': 0,
      'op': 45,
      'w': 400,
      'h': 400,
      'nm': 'Success Pulse',
      'ddd': 0,
      'assets': [],
      'layers': [
        {
          'ty': 4,
          'nm': 'Pulse Ring',
          'sr': 1,
          'ks': {
            'o': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [100],
                },
                {
                  't': 45,
                  's': [0],
                },
              ],
            },
            'r': {'a': 0, 'k': 0},
            'p': {
              'a': 0,
              'k': [200, 200],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [80, 80],
                },
                {
                  't': 45,
                  's': [150, 150],
                },
              ],
            },
          },
          'shapes': [
            {
              'ty': 'el', // Ellipse
              's': {
                'a': 0,
                'k': [100, 100],
              },
            },
            {
              'ty': 'st', // Stroke
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              }, // Green
              'o': {'a': 0, 'k': 100},
              'w': {'a': 0, 'k': 12},
            }
          ],
        },
        {
          'ty': 4,
          'nm': 'Inner Circle',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {'a': 0, 'k': 0},
            'p': {
              'a': 0,
              'k': [200, 200],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [100, 100],
                },
                {
                  't': 15,
                  's': [110, 110],
                },
                {
                  't': 30,
                  's': [100, 100],
                },
              ],
            },
          },
          'shapes': [
            {
              'ty': 'el',
              's': {
                'a': 0,
                'k': [80, 80],
              },
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              },
              'o': {'a': 0, 'k': 30},
            }
          ],
        }
      ],
    };
  }

  /// Generates error shake animation
  Map<String, dynamic> generateErrorShake() {
    return {
      'v': '5.7.4',
      'fr': 30,
      'ip': 0,
      'op': 30,
      'w': 400,
      'h': 400,
      'nm': 'Error Shake',
      'ddd': 0,
      'assets': [],
      'layers': [
        {
          'ty': 4,
          'nm': 'X Mark',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [0],
                },
                {
                  't': 5,
                  's': [-10],
                },
                {
                  't': 10,
                  's': [10],
                },
                {
                  't': 15,
                  's': [-8],
                },
                {
                  't': 20,
                  's': [8],
                },
                {
                  't': 25,
                  's': [0],
                },
              ],
            },
            'p': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [200, 200],
                },
                {
                  't': 5,
                  's': [190, 200],
                },
                {
                  't': 10,
                  's': [210, 200],
                },
                {
                  't': 15,
                  's': [192, 200],
                },
                {
                  't': 20,
                  's': [208, 200],
                },
                {
                  't': 25,
                  's': [200, 200],
                },
              ],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [0, 0],
                },
                {
                  't': 10,
                  's': [120, 120],
                },
                {
                  't': 25,
                  's': [100, 100],
                },
              ],
            },
          },
          'shapes': [
            {
              'ty': 'gr',
              'nm': 'X Shape',
              'np': 3,
              'cix': 2,
              'bm': 0,
              'ix': 1,
              'it': [
                {
                  'ty': 'sh',
                  'nm': 'Line 1',
                  'ks': {
                    'a': 0,
                    'k': {
                      'i': [
                        [0, 0],
                        [0, 0],
                      ],
                      'o': [
                        [0, 0],
                        [0, 0],
                      ],
                      'v': [
                        [-30, -30],
                        [30, 30],
                      ],
                      'c': false,
                    },
                  },
                },
                {
                  'ty': 'sh',
                  'nm': 'Line 2',
                  'ks': {
                    'a': 0,
                    'k': {
                      'i': [
                        [0, 0],
                        [0, 0],
                      ],
                      'o': [
                        [0, 0],
                        [0, 0],
                      ],
                      'v': [
                        [30, -30],
                        [-30, 30],
                      ],
                      'c': false,
                    },
                  },
                },
                {
                  'ty': 'st',
                  'c': {
                    'a': 0,
                    'k': [0.9, 0.2, 0.2, 1],
                  }, // Red
                  'o': {'a': 0, 'k': 100},
                  'w': {'a': 0, 'k': 10},
                  'lc': 2,
                }
              ],
            }
          ],
        }
      ],
    };
  }

  /// Generates Ville walk cycle animation
  Map<String, dynamic> generateVilleWalk() {
    return {
      'v': '5.7.4',
      'fr': 24,
      'ip': 0,
      'op': 24,
      'w': 400,
      'h': 400,
      'nm': 'Ville Walk',
      'ddd': 0,
      'assets': [],
      'layers': [
        // Body (with bounce)
        {
          'ty': 4,
          'nm': 'Body',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {'a': 0, 'k': 0},
            'p': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [200, 200],
                },
                {
                  't': 6,
                  's': [200, 195],
                },
                {
                  't': 12,
                  's': [200, 200],
                },
                {
                  't': 18,
                  's': [200, 195],
                },
                {
                  't': 24,
                  's': [200, 200],
                },
              ],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
          },
          'shapes': [
            {
              'ty': 'rc',
              's': {
                'a': 0,
                'k': [80, 120],
              },
              'r': {'a': 0, 'k': 12},
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
        // Head (bobs with body)
        {
          'ty': 4,
          'nm': 'Head',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {'a': 0, 'k': 0},
            'p': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [200, 120],
                },
                {
                  't': 6,
                  's': [200, 115],
                },
                {
                  't': 12,
                  's': [200, 120],
                },
                {
                  't': 18,
                  's': [200, 115],
                },
                {
                  't': 24,
                  's': [200, 120],
                },
              ],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
          },
          'shapes': [
            {
              'ty': 'el',
              's': {
                'a': 0,
                'k': [50, 50],
              },
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.95, 0.83, 0.63, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
        // Left leg (swings back-forward)
        {
          'ty': 4,
          'nm': 'Left Leg',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [-20],
                },
                {
                  't': 12,
                  's': [20],
                },
                {
                  't': 24,
                  's': [-20],
                },
              ],
            },
            'p': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [185, 260],
                },
                {
                  't': 6,
                  's': [185, 255],
                },
                {
                  't': 12,
                  's': [185, 260],
                },
                {
                  't': 18,
                  's': [185, 255],
                },
                {
                  't': 24,
                  's': [185, 260],
                },
              ],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
          },
          'shapes': [
            {
              'ty': 'rc',
              's': {
                'a': 0,
                'k': [20, 50],
              },
              'r': {'a': 0, 'k': 8},
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
        // Right leg (opposite phase)
        {
          'ty': 4,
          'nm': 'Right Leg',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [20],
                },
                {
                  't': 12,
                  's': [-20],
                },
                {
                  't': 24,
                  's': [20],
                },
              ],
            },
            'p': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [215, 260],
                },
                {
                  't': 6,
                  's': [215, 255],
                },
                {
                  't': 12,
                  's': [215, 260],
                },
                {
                  't': 18,
                  's': [215, 255],
                },
                {
                  't': 24,
                  's': [215, 260],
                },
              ],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
          },
          'shapes': [
            {
              'ty': 'rc',
              's': {
                'a': 0,
                'k': [20, 50],
              },
              'r': {'a': 0, 'k': 8},
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
        // Left arm (opposite to right leg)
        {
          'ty': 4,
          'nm': 'Left Arm',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [15],
                },
                {
                  't': 12,
                  's': [-15],
                },
                {
                  't': 24,
                  's': [15],
                },
              ],
            },
            'p': {
              'a': 0,
              'k': [175, 180],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
          },
          'shapes': [
            {
              'ty': 'rc',
              's': {
                'a': 0,
                'k': [15, 45],
              },
              'r': {'a': 0, 'k': 8},
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
        // Right arm (opposite to left leg)
        {
          'ty': 4,
          'nm': 'Right Arm',
          'sr': 1,
          'ks': {
            'o': {'a': 0, 'k': 100},
            'r': {
              'a': 1,
              'k': [
                {
                  't': 0,
                  's': [-15],
                },
                {
                  't': 12,
                  's': [15],
                },
                {
                  't': 24,
                  's': [-15],
                },
              ],
            },
            'p': {
              'a': 0,
              'k': [225, 180],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
          },
          'shapes': [
            {
              'ty': 'rc',
              's': {
                'a': 0,
                'k': [15, 45],
              },
              'r': {'a': 0, 'k': 8},
            },
            {
              'ty': 'fl',
              'c': {
                'a': 0,
                'k': [0.3, 0.8, 0.3, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
      ],
    };
  }

  // Helper methods
  Map<String, dynamic> _createStarPath(double size) {
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    final points = <List<double>>[];

    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi * 2 / 10) - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      points.add([
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      ]);
    }

    return {
      'ty': 'sh',
      'nm': 'Star Path',
      'ks': {
        'a': 0,
        'k': {
          'i': List.generate(10, (_) => [0, 0]),
          'o': List.generate(10, (_) => [0, 0]),
          'v': points,
          'c': true,
        },
      },
    };
  }

  List<double> _randomConfettiColor(math.Random random) {
    final colors = [
      [1.0, 0.2, 0.3, 1.0], // Red
      [0.2, 0.6, 1.0, 1.0], // Blue
      [1.0, 0.8, 0.2, 1.0], // Yellow
      [0.4, 0.9, 0.4, 1.0], // Green
      [0.9, 0.4, 0.9, 1.0], // Purple
      [1.0, 0.5, 0.2, 1.0], // Orange
    ];
    return colors[random.nextInt(colors.length)];
  }
}
