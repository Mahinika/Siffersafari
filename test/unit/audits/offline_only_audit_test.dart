import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline-only audit', () {
    test('lib/ innehaller inga tydliga natverksanrop', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final forbiddenPatterns = <RegExp>[
        RegExp(r'package:http/'),
        RegExp(r'package:http/http\.dart'),
        RegExp(r'\bdio\b'),
        RegExp(r'\bClient\s*\('),
        RegExp(r'\bHttpClient\s*\('),
        RegExp(r'\bWebSocket\s*\('),
        RegExp(r'\bSocket\s*\('),
        RegExp(r'\bInternetAddress\b'),
        RegExp(r'\bSocketException\b'),
        RegExp(r'\bRawDatagramSocket\b'),
        RegExp(r'https?://'),
      ];

      final violations = <String>[];
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final path = file.path.replaceAll('\\', '/');
        final content = file.readAsStringSync();

        for (final pattern in forbiddenPatterns) {
          if (pattern.hasMatch(content)) {
            violations.add('$path -> ${pattern.pattern}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Offline-first policy broken. Found forbidden patterns: '
            '${violations.join(', ')}',
      );
    });
  });
}
