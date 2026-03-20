// ignore_for_file: avoid_print

/// Generates SVG parts for the mascot character based on visual spec.
///
/// Usage: dart run scripts/generate_mascot_svg_parts.dart
///
/// Reads: assets/characters/mascot/config/mascot_visual_spec.json
/// Outputs: assets/characters/mascot/svg/*.svg (12 files)
library;

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🎨 Mascot SVG Part Generator');
  print('━' * 50);

  // Load spec
  final specFile =
      File('assets/characters/mascot/config/mascot_visual_spec.json');
  if (!specFile.existsSync()) {
    print('❌ Error: mascot_visual_spec.json not found');
    exit(1);
  }

  final spec = jsonDecode(await specFile.readAsString());
  final colors = spec['colors'] as Map<String, dynamic>;
  final proportions = spec['proportions'] as Map<String, dynamic>;
  final styleSource = spec['styleSettings'] ?? spec['style'];
  final style = styleSource is Map<String, dynamic>
      ? styleSource
      : <String, dynamic>{
          'strokeWidth': 4,
          'cornerRadius': 14,
        };

  final outputDir = Directory('assets/characters/mascot/svg');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Base dimensions
  const double baseSize = 400.0;
  const double headSize = 200.0;
  final bodySize = headSize / (proportions['headToBodyRatio'] as num);

  final generator = MascotSvgGenerator(
    colors: colors,
    proportions: proportions,
    style: style,
    baseSize: baseSize,
    headSize: headSize,
    bodySize: bodySize,
  );

  // Generate all parts
  final parts = {
    'mascot_head': generator.generateHead(),
    'mascot_eyes_open': generator.generateEyesOpen(),
    'mascot_eyes_closed': generator.generateEyesClosed(),
    'mascot_mouth_smile': generator.generateMouthSmile(),
    'mascot_mouth_sad': generator.generateMouthSad(),
    'mascot_mouth_neutral': generator.generateMouthNeutral(),
    'mascot_body': generator.generateBody(),
    'mascot_arm_left': generator.generateArmLeft(),
    'mascot_arm_right': generator.generateArmRight(),
    'mascot_leg_left': generator.generateLegLeft(),
    'mascot_leg_right': generator.generateLegRight(),
    'mascot_antennas': generator.generateAntennas(),
  };

  // Write files
  for (final entry in parts.entries) {
    final file = File('${outputDir.path}/${entry.key}.svg');
    await file.writeAsString(entry.value);
    print('✅ Generated: ${entry.key}.svg');
  }

  print('━' * 50);
  print('🎉 Generated ${parts.length} SVG parts successfully!');
}

class MascotSvgGenerator {
  final Map<String, dynamic> colors;
  final Map<String, dynamic> proportions;
  final Map<String, dynamic> style;
  final double baseSize;
  final double headSize;
  final double bodySize;

  MascotSvgGenerator({
    required this.colors,
    required this.proportions,
    required this.style,
    required this.baseSize,
    required this.headSize,
    required this.bodySize,
  });

  String _wrapSVG(
    String content, {
    double? width,
    double? height,
    String? viewBox,
  }) {
    final w = width ?? baseSize;
    final h = height ?? baseSize;
    final vb = viewBox ?? '0 0 $w $h';
    return '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="$w" height="$h" viewBox="$vb" xmlns="http://www.w3.org/2000/svg">
$content
</svg>''';
  }

  String generateHead() {
    final cx = baseSize / 2;
    final cy = headSize / 2;
    final rx = headSize / 2;
    final ry = headSize / 2.2;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Head base -->
  <ellipse cx="$cx" cy="$cy" rx="$rx" ry="$ry" 
           fill="${colors['skin']}" 
           stroke="${colors['outline']}" 
           stroke-width="$strokeW"/>
  
  <!-- Subtle cheek blush -->
  <ellipse cx="${cx - 50}" cy="${cy + 20}" rx="25" ry="18" 
           fill="#FFB3BA" opacity="0.4"/>
  <ellipse cx="${cx + 50}" cy="${cy + 20}" rx="25" ry="18" 
           fill="#FFB3BA" opacity="0.4"/>
''',
      height: headSize,
    );
  }

  String generateEyesOpen() {
    final cx = baseSize / 2;
    final eyeSize = headSize * (proportions['eyeSizeRelativeToHead'] as num);
    final eyeOffset = eyeSize * 1.8;
    final cy = headSize / 3;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Left eye -->
  <circle cx="${cx - eyeOffset}" cy="$cy" r="$eyeSize" 
          fill="white" 
          stroke="${colors['outline']}" 
          stroke-width="${strokeW * 0.6}"/>
  <circle cx="${cx - eyeOffset}" cy="$cy" r="${eyeSize * 0.5}" 
          fill="${colors['eyes']}"/>
  <circle cx="${cx - eyeOffset + eyeSize * 0.2}" cy="${cy - eyeSize * 0.2}" r="${eyeSize * 0.25}" 
          fill="white" opacity="0.9"/>
  
  <!-- Right eye -->
  <circle cx="${cx + eyeOffset}" cy="$cy" r="$eyeSize" 
          fill="white" 
          stroke="${colors['outline']}" 
          stroke-width="${strokeW * 0.6}"/>
  <circle cx="${cx + eyeOffset}" cy="$cy" r="${eyeSize * 0.5}" 
          fill="${colors['eyes']}"/>
  <circle cx="${cx + eyeOffset + eyeSize * 0.2}" cy="${cy - eyeSize * 0.2}" r="${eyeSize * 0.25}" 
          fill="white" opacity="0.9"/>
''',
      height: headSize * 0.6,
    );
  }

  String generateEyesClosed() {
    final cx = baseSize / 2;
    final eyeSize = headSize * (proportions['eyeSizeRelativeToHead'] as num);
    final eyeOffset = eyeSize * 1.8;
    final cy = headSize / 3;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Left eye closed -->
  <path d="M ${cx - eyeOffset - eyeSize} $cy Q ${cx - eyeOffset} ${cy + 5} ${cx - eyeOffset + eyeSize} $cy" 
        stroke="${colors['eyes']}" 
        stroke-width="$strokeW" 
        stroke-linecap="round" 
        fill="none"/>
  
  <!-- Right eye closed -->
  <path d="M ${cx + eyeOffset - eyeSize} $cy Q ${cx + eyeOffset} ${cy + 5} ${cx + eyeOffset + eyeSize} $cy" 
        stroke="${colors['eyes']}" 
        stroke-width="$strokeW" 
        stroke-linecap="round" 
        fill="none"/>
''',
      height: headSize * 0.6,
    );
  }

  String generateMouthSmile() {
    final cx = baseSize / 2;
    final mouthWidth =
        headSize * (proportions['mouthWidthRelativeToHead'] as num);
    final cy = headSize * 0.65;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Smile curve -->
  <path d="M ${cx - mouthWidth} $cy Q $cx ${cy + 25} ${cx + mouthWidth} $cy" 
        stroke="${colors['mouth']}" 
        stroke-width="$strokeW" 
        stroke-linecap="round" 
        fill="none"/>
''',
      height: headSize * 0.4,
    );
  }

  String generateMouthSad() {
    final cx = baseSize / 2;
    final mouthWidth =
        headSize * (proportions['mouthWidthRelativeToHead'] as num);
    final cy = headSize * 0.7;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Sad curve -->
  <path d="M ${cx - mouthWidth} ${cy + 15} Q $cx $cy ${cx + mouthWidth} ${cy + 15}" 
        stroke="${colors['mouth']}" 
        stroke-width="$strokeW" 
        stroke-linecap="round" 
        fill="none"/>
''',
      height: headSize * 0.4,
    );
  }

  String generateMouthNeutral() {
    final cx = baseSize / 2;
    final mouthWidth =
        headSize * (proportions['mouthWidthRelativeToHead'] as num);
    final cy = headSize * 0.68;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Neutral line -->
  <line x1="${cx - mouthWidth}" y1="$cy" x2="${cx + mouthWidth}" y2="$cy" 
        stroke="${colors['mouth']}" 
        stroke-width="$strokeW" 
        stroke-linecap="round"/>
''',
      height: headSize * 0.4,
    );
  }

  String generateBody() {
    final cx = baseSize / 2;
    final width = bodySize * 0.8;
    final height = bodySize;
    final radius = style['cornerRadius'] as num;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Body main shape -->
  <rect x="${cx - width / 2}" y="20" 
        width="$width" height="$height" 
        rx="$radius" ry="$radius"
        fill="${colors['bodyPrimary']}" 
        stroke="${colors['outline']}" 
        stroke-width="$strokeW"/>
  
  <!-- Belly detail -->
  <ellipse cx="$cx" cy="${height * 0.6}" 
           rx="${width * 0.35}" ry="${height * 0.25}" 
           fill="${colors['bodySecondary']}" 
           opacity="0.6"/>
''',
      height: bodySize + 40,
    );
  }

  String generateArmLeft() {
    final armLength =
        bodySize * (proportions['armLengthRelativeToBody'] as num);
    final armWidth = 35.0;
    final radius = style['cornerRadius'] as num;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Left arm -->
  <rect x="30" y="20" 
        width="$armWidth" height="$armLength" 
        rx="${radius * 0.8}" ry="${radius * 0.8}"
        fill="${colors['bodyPrimary']}" 
        stroke="${colors['outline']}" 
        stroke-width="$strokeW"/>
  
  <!-- Hand -->
  <circle cx="${30 + armWidth / 2}" cy="${20 + armLength}" 
          r="22" 
          fill="${colors['skin']}" 
          stroke="${colors['outline']}" 
          stroke-width="$strokeW"/>
''',
      height: armLength + 50,
    );
  }

  String generateArmRight() {
    final armLength =
        bodySize * (proportions['armLengthRelativeToBody'] as num);
    final armWidth = 35.0;
    final radius = style['cornerRadius'] as num;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Right arm -->
  <rect x="335" y="20" 
        width="$armWidth" height="$armLength" 
        rx="${radius * 0.8}" ry="${radius * 0.8}"
        fill="${colors['bodyPrimary']}" 
        stroke="${colors['outline']}" 
        stroke-width="$strokeW"/>
  
  <!-- Hand -->
  <circle cx="${335 + armWidth / 2}" cy="${20 + armLength}" 
          r="22" 
          fill="${colors['skin']}" 
          stroke="${colors['outline']}" 
          stroke-width="$strokeW"/>
''',
      height: armLength + 50,
    );
  }

  String generateLegLeft() {
    final legLength =
        bodySize * (proportions['legLengthRelativeToBody'] as num);
    final legWidth = 40.0;
    final radius = style['cornerRadius'] as num;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Left leg -->
  <rect x="140" y="20" 
        width="$legWidth" height="$legLength" 
        rx="${radius * 0.7}" ry="${radius * 0.7}"
        fill="${colors['bodyPrimary']}" 
        stroke="${colors['outline']}" 
        stroke-width="$strokeW"/>
  
  <!-- Foot -->
  <ellipse cx="${140 + legWidth / 2}" cy="${20 + legLength + 12}" 
           rx="32" ry="20" 
           fill="${colors['skin']}" 
           stroke="${colors['outline']}" 
           stroke-width="$strokeW"/>
''',
      height: legLength + 60,
    );
  }

  String generateLegRight() {
    final legLength =
        bodySize * (proportions['legLengthRelativeToBody'] as num);
    final legWidth = 40.0;
    final radius = style['cornerRadius'] as num;
    final strokeW = style['strokeWidth'] as num;

    return _wrapSVG(
      '''
  <!-- Right leg -->
  <rect x="220" y="20" 
        width="$legWidth" height="$legLength" 
        rx="${radius * 0.7}" ry="${radius * 0.7}"
        fill="${colors['bodyPrimary']}" 
        stroke="${colors['outline']}" 
        stroke-width="$strokeW"/>
  
  <!-- Foot -->
  <ellipse cx="${220 + legWidth / 2}" cy="${20 + legLength + 12}" 
           rx="32" ry="20" 
           fill="${colors['skin']}" 
           stroke="${colors['outline']}" 
           stroke-width="$strokeW"/>
''',
      height: legLength + 60,
    );
  }

  String generateAntennas() {
    final cx = baseSize / 2;
    final antennaRatio =
      (proportions['antennaLengthRelativeToHead'] as num?) ?? 0.28;
    final antennaLength = headSize * antennaRatio;
    final strokeW = style['strokeWidth'] as num;
    final ballSize = 14.0;

    return _wrapSVG(
      '''
  <!-- Left antenna -->
  <line x1="${cx - 40}" y1="20" x2="${cx - 60}" y2="${20 - antennaLength}" 
        stroke="${colors['bodyPrimary']}" 
        stroke-width="${strokeW * 0.8}" 
        stroke-linecap="round"/>
  <circle cx="${cx - 60}" cy="${20 - antennaLength}" 
          r="$ballSize" 
          fill="${colors['antenna']}" 
          stroke="${colors['outline']}" 
          stroke-width="${strokeW * 0.6}"/>
  
  <!-- Right antenna -->
  <line x1="${cx + 40}" y1="20" x2="${cx + 60}" y2="${20 - antennaLength}" 
        stroke="${colors['bodyPrimary']}" 
        stroke-width="${strokeW * 0.8}" 
        stroke-linecap="round"/>
  <circle cx="${cx + 60}" cy="${20 - antennaLength}" 
          r="$ballSize" 
          fill="${colors['antenna']}" 
          stroke="${colors['outline']}" 
          stroke-width="${strokeW * 0.6}"/>
''',
      height: antennaLength + 40,
    );
  }
}
