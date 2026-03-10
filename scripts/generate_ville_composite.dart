// ignore_for_file: avoid_print, dangling_library_doc_comments

/// Generates a composite SVG of complete Ville character.
/// 
/// Usage: dart run scripts/generate_ville_composite.dart
/// 
/// Reads: assets/characters/ville/svg/ville_*.svg (individual parts)
/// Outputs: assets/characters/ville/svg/ville_composite.svg (complete character)

import 'dart:io';

void main() async {
  print('🎨 Ville Composite Generator');
  print('━' * 50);

  final outputFile = File('assets/characters/ville/svg/ville_composite.svg');
  
  // Create complete Ville character
  final compositeSvg = generateCompositeSvg();
  
  await outputFile.writeAsString(compositeSvg);
  print('✅ Generated: ville_composite.svg');
  print('━' * 50);
  print('🎉 Complete Ville character ready!');
  print('');
  print('Preview: Open assets/characters/ville/svg/ville_composite.svg');
}

String generateCompositeSvg() {
  // Full character composition with all parts in correct layers
  return '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="400" height="600" viewBox="0 0 400 600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .ville-part { opacity: 1; }
    </style>
  </defs>
  
  <!-- Background (optional) -->
  
  <!-- Layer 1: Legs (bottom) -->
  <g id="legs" class="ville-part" transform="translate(0, 250)">
    <!-- Left leg -->
    <rect x="140" y="20" 
          width="40" height="294" 
          rx="8.4" ry="8.4"
          fill="#4CAF50" 
          stroke="#2E2E2E" 
          stroke-width="4"/>
    <ellipse cx="160" cy="326" 
             rx="32" ry="20" 
             fill="#F2D3A0" 
             stroke="#2E2E2E" 
             stroke-width="4"/>
    
    <!-- Right leg -->
    <rect x="220" y="20" 
          width="40" height="294" 
          rx="8.4" ry="8.4"
          fill="#4CAF50" 
          stroke="#2E2E2E" 
          stroke-width="4"/>
    <ellipse cx="240" cy="326" 
             rx="32" ry="20" 
             fill="#F2D3A0" 
             stroke="#2E2E2E" 
             stroke-width="4"/>
  </g>
  
  <!-- Layer 2: Body -->
  <g id="body" class="ville-part" transform="translate(0, 150)">
    <rect x="120" y="20" 
          width="160" height="327.27" 
          rx="12" ry="12"
          fill="#4CAF50" 
          stroke="#2E2E2E" 
          stroke-width="4"/>
    
    <!-- Belly detail -->
    <ellipse cx="200" cy="216.36" 
             rx="56" ry="81.82" 
             fill="#81C784" 
             opacity="0.6"/>
  </g>
  
  <!-- Layer 3: Arms -->
  <g id="arms" class="ville-part">
    <!-- Left arm -->
    <g transform="translate(0, 170)">
      <rect x="30" y="20" 
            width="35" height="261.82" 
            rx="9.6" ry="9.6"
            fill="#4CAF50" 
            stroke="#2E2E2E" 
            stroke-width="4"/>
      <circle cx="47.5" cy="281.82" 
              r="22" 
              fill="#F2D3A0" 
              stroke="#2E2E2E" 
              stroke-width="4"/>
    </g>
    
    <!-- Right arm -->
    <g transform="translate(0, 170)">
      <rect x="335" y="20" 
            width="35" height="261.82" 
            rx="9.6" ry="9.6"
            fill="#4CAF50" 
            stroke="#2E2E2E" 
            stroke-width="4"/>
      <circle cx="352.5" cy="281.82" 
              r="22" 
              fill="#F2D3A0" 
              stroke="#2E2E2E" 
              stroke-width="4"/>
    </g>
  </g>
  
  <!-- Layer 4: Head -->
  <g id="head" class="ville-part" transform="translate(0, 30)">
    <ellipse cx="200" cy="100" rx="100" ry="90.91" 
             fill="#F2D3A0" 
             stroke="#2E2E2E" 
             stroke-width="4"/>
    
    <!-- Cheek blush left -->
    <ellipse cx="150" cy="120" rx="25" ry="18" 
             fill="#FFB3BA" opacity="0.4"/>
    <!-- Cheek blush right -->
    <ellipse cx="250" cy="120" rx="25" ry="18" 
             fill="#FFB3BA" opacity="0.4"/>
  </g>
  
  <!-- Layer 5: Eyes (open by default) -->
  <g id="eyes" class="ville-part" transform="translate(0, 30)">
    <!-- Left eye -->
    <circle cx="165.6" cy="66.67" r="18" 
            fill="white" 
            stroke="#2E2E2E" 
            stroke-width="2.4"/>
    <circle cx="165.6" cy="66.67" r="9" 
            fill="#333333"/>
    <circle cx="169.2" cy="63.07" r="4.5" 
            fill="white" opacity="0.9"/>
    
    <!-- Right eye -->
    <circle cx="234.4" cy="66.67" r="18" 
            fill="white" 
            stroke="#2E2E2E" 
            stroke-width="2.4"/>
    <circle cx="234.4" cy="66.67" r="9" 
            fill="#333333"/>
    <circle cx="238" cy="63.07" r="4.5" 
            fill="white" opacity="0.9"/>
  </g>
  
  <!-- Layer 6: Mouth (smile by default) -->
  <g id="mouth" class="ville-part" transform="translate(0, 30)">
    <path d="M 130 130 Q 200 155 270 130" 
          stroke="#333333" 
          stroke-width="4" 
          stroke-linecap="round" 
          fill="none"/>
  </g>
  
  <!-- Layer 7: Antennas (top) -->
  <g id="antennas" class="ville-part" transform="translate(0, 30)">
    <!-- Left antenna -->
    <line x1="160" y1="20" x2="140" y2="-100" 
          stroke="#4CAF50" 
          stroke-width="3.2" 
          stroke-linecap="round"/>
    <circle cx="140" cy="-100" 
            r="14" 
            fill="#FF6F61" 
            stroke="#2E2E2E" 
            stroke-width="2.4"/>
    
    <!-- Right antenna -->
    <line x1="240" y1="20" x2="260" y2="-100" 
          stroke="#4CAF50" 
          stroke-width="3.2" 
          stroke-linecap="round"/>
    <circle cx="260" cy="-100" 
            r="14" 
            fill="#FF6F61" 
            stroke="#2E2E2E" 
            stroke-width="2.4"/>
  </g>
</svg>''';
}
