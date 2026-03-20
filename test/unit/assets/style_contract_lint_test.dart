import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<ProcessResult> _runAssetLint() async {
  final commands = Platform.isWindows
  ? <String>['python', 'py']
  : <String>['python3', 'python'];

  ProcessException? lastError;

  for (final command in commands) {
    try {
      final result = await Process.run(
        command,
        const ['tools/pipeline.py', 'lint-assets', '--strict'],
      );
      if (result.exitCode == 0) {
        return result;
      }
      return result;
    } on ProcessException catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? const ProcessException('python', ['tools/pipeline.py']);
}

Future<ProcessResult> _runAssetLintWarnOnlyWithReport() async {
  final commands = Platform.isWindows
  ? <String>['python', 'py']
  : <String>['python3', 'python'];

  ProcessException? lastError;

  for (final command in commands) {
    try {
      final result = await Process.run(
        command,
        const [
          'tools/pipeline.py',
          'lint-assets',
          '--strict',
          '--warn-only',
          '--report-path',
          'artifacts/asset_lint_report_test.json',
        ],
      );
      return result;
    } on ProcessException catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? const ProcessException('python', ['tools/pipeline.py']);
}

void main() {
  group('[Unit] Asset style contract', () {
    test('style contract exists', () {
      expect(File('specs/style_contract.yaml').existsSync(), isTrue);
    });

    test('lint-assets strict passes', () async {
      final result = await _runAssetLint();
      expect(
        result.exitCode,
        0,
        reason:
            'lint-assets failed:\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
      );
    });

    test('lint-assets warn-only writes report', () async {
      final reportFile = File('artifacts/asset_lint_report_test.json');
      if (reportFile.existsSync()) {
        reportFile.deleteSync();
      }

      final result = await _runAssetLintWarnOnlyWithReport();
      expect(
        result.exitCode,
        0,
        reason:
            'lint-assets warn-only failed:\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
      );
      expect(reportFile.existsSync(), isTrue);

      reportFile.deleteSync();
    });
  });
}
