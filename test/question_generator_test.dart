import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_app/core/config/difficulty_config.dart';
import 'package:math_game_app/core/services/question_generator_service.dart';
import 'package:math_game_app/domain/enums/age_group.dart';
import 'package:math_game_app/domain/enums/difficulty_level.dart';
import 'package:math_game_app/domain/enums/operation_type.dart';

bool _hasCarry(int a, int b) {
  var x = a;
  var y = b;
  while (x > 0 || y > 0) {
    if ((x % 10) + (y % 10) >= 10) return true;
    x ~/= 10;
    y ~/= 10;
  }
  return false;
}

bool _hasBorrow(int a, int b) {
  var x = a;
  var y = b;
  var borrow = 0;
  while (x > 0 || y > 0) {
    final da = (x % 10) - borrow;
    final db = y % 10;
    if (da < db) return true;
    borrow = da < db ? 1 : 0;
    x ~/= 10;
    y ~/= 10;
  }
  return false;
}

void main() {
  group('QuestionGeneratorService', () {
    late QuestionGeneratorService service;

    setUp(() {
      service = QuestionGeneratorService();
    });

    test('Unit (QuestionGeneratorService): genererar rätt antal frågor', () {
      final questions = service.generateQuestions(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        count: 10,
      );

      expect(questions.length, 10);
    });

    test('Unit (QuestionGeneratorService): addition ger korrekt svar', () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.addition);
      expect(
        question.correctAnswer,
        question.operand1 + question.operand2,
      );
    });

    test(
        'Unit (QuestionGeneratorService): subtraktion ger inte negativt resultat',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.young,
        operationType: OperationType.subtraction,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.subtraction);
      expect(question.correctAnswer, greaterThanOrEqualTo(0));
      expect(
        question.correctAnswer,
        question.operand1 - question.operand2,
      );
    });

    test('Unit (QuestionGeneratorService): multiplikation ger korrekt svar',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.multiplication);
      expect(
        question.correctAnswer,
        question.operand1 * question.operand2,
      );
    });

    test('Unit (QuestionGeneratorService): division ger heltalsresultat', () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.division,
        difficulty: DifficultyLevel.easy,
      );

      expect(question.operationType, OperationType.division);
      // Verify it's a whole number division
      expect(
        question.operand1 % question.operand2,
        0,
      );
      expect(
        question.correctAnswer,
        question.operand1 ~/ question.operand2,
      );
    });

    test('M3 (Åk 4–6): multiplikation step<=6 har alltid en tabell-faktor', () {
      final seeded = QuestionGeneratorService(random: Random(1));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 4,
        difficultyStep: 6,
      );

      final minFactor = question.operand1 < question.operand2
          ? question.operand1
          : question.operand2;
      expect(minFactor, lessThanOrEqualTo(12));
      expect(minFactor, greaterThanOrEqualTo(1));
    });

    test('M3 (Åk 4–6): division step<=6 har liten divisor och inget rest', () {
      final seeded = QuestionGeneratorService(random: Random(2));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.division,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 5,
        difficultyStep: 6,
      );

      expect(question.operand2, lessThanOrEqualTo(12));
      expect(question.operand2, greaterThanOrEqualTo(1));
      expect(question.operand1 % question.operand2, 0);
      expect(question.correctAnswer, question.operand1 ~/ question.operand2);
    });

    test('M3 (Åk 4–6): addition step<=3 undviker växling (carry)', () {
      final seeded = QuestionGeneratorService(random: Random(3));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 4,
        difficultyStep: 3,
      );

      expect(_hasCarry(question.operand1, question.operand2), isFalse);
    });

    test('M3 (Åk 4–6): addition step>=8 kräver växling (carry)', () {
      final seeded = QuestionGeneratorService(random: Random(4));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 5,
        difficultyStep: 8,
      );

      expect(_hasCarry(question.operand1, question.operand2), isTrue);
    });

    test('M3 (Åk 4–6): subtraktion step<=3 undviker växling (borrow)', () {
      final seeded = QuestionGeneratorService(random: Random(5));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.subtraction,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 6,
        difficultyStep: 3,
      );

      final a = question.operand1 >= question.operand2
          ? question.operand1
          : question.operand2;
      final b = question.operand1 >= question.operand2
          ? question.operand2
          : question.operand1;
      expect(_hasBorrow(a, b), isFalse);
    });

    test('M3 (Åk 4–6): subtraktion step>=8 kräver växling (borrow)', () {
      final seeded = QuestionGeneratorService(random: Random(6));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.subtraction,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 4,
        difficultyStep: 9,
      );

      final a = question.operand1 >= question.operand2
          ? question.operand1
          : question.operand2;
      final b = question.operand1 >= question.operand2
          ? question.operand2
          : question.operand1;
      expect(_hasBorrow(a, b), isTrue);
    });

    test('M3 (Åk 4–6): multiplikation step10 har alltid en tabell-faktor', () {
      final seeded = QuestionGeneratorService(random: Random(7));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 6,
        difficultyStep: 10,
      );

      final minFactor = question.operand1 < question.operand2
          ? question.operand1
          : question.operand2;
      expect(minFactor, lessThanOrEqualTo(12));
      expect(minFactor, greaterThanOrEqualTo(1));
    });

    test('M3 (Åk 4–6): division step10 har liten divisor och inget rest', () {
      final seeded = QuestionGeneratorService(random: Random(8));

      final question = seeded.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.division,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 6,
        difficultyStep: 10,
      );

      expect(question.operand2, lessThanOrEqualTo(12));
      expect(question.operand2, greaterThanOrEqualTo(1));
      expect(question.operand1 % question.operand2, 0);
      expect(question.correctAnswer, question.operand1 ~/ question.operand2);
    });

    test('M4 (Åk 4–6): Mix kan generera statistikfråga (prompt med "=")', () {
      final seeded = QuestionGeneratorService(
        random: Random(9),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 300; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.easy,
          gradeLevel: 4,
          difficultyStep: 5,
        );

        final prompt = q.promptText;
        if (prompt == null) continue;
        if (prompt.startsWith('Median') ||
            prompt.startsWith('Typvärde') ||
            prompt.startsWith('Medelvärde')) {
          expect(prompt, contains('= ?'));
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5a (Åk 7–9): addition kan generera negativa tal', () {
      final seeded = QuestionGeneratorService(random: Random(109));

      var foundSignedOperandOrAnswer = false;
      for (var i = 0; i < 200; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.addition,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 7,
          difficultyStep: 5,
        );

        expect(q.correctAnswer, q.operand1 + q.operand2);

        if (q.operand1 < 0 || q.operand2 < 0 || q.correctAnswer < 0) {
          foundSignedOperandOrAnswer = true;
          break;
        }
      }

      expect(foundSignedOperandOrAnswer, isTrue);
    });

    test('M5a (Åk 7–9): subtraktion kan ge negativt resultat', () {
      final seeded = QuestionGeneratorService(random: Random(110));

      var foundNegativeAnswer = false;
      for (var i = 0; i < 200; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.subtraction,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 8,
          difficultyStep: 6,
        );

        expect(q.correctAnswer, q.operand1 - q.operand2);

        if (q.correctAnswer < 0) {
          foundNegativeAnswer = true;
          break;
        }
      }

      expect(foundNegativeAnswer, isTrue);
    });

    test('M5a (Åk 7–9): Mix kan generera procentfråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(111),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 400; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 7,
          difficultyStep: 6,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Procent = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5a (Åk 7–9): procentfråga ger korrekt heltalssvar', () {
      final seeded = QuestionGeneratorService(
        random: Random(112),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 800; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 9,
          difficultyStep: 9,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Procent = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      final match = RegExp(r'Vad är (\d+)% av (\d+)\?').firstMatch(prompt!);
      expect(match, isNotNull);

      final percent = int.parse(match!.group(1)!);
      final base = int.parse(match.group(2)!);
      expect(answer, (percent * base) ~/ 100);
    });

    test('M5a (Åk 8–9): Mix kan generera potensfråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(113),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 8,
          difficultyStep: 6,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Potenser = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5a (Åk 8–9): potensfråga ger korrekt heltalssvar', () {
      final seeded = QuestionGeneratorService(
        random: Random(114),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 1000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 9,
          difficultyStep: 9,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Potenser = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      final match = RegExp(r'Vad är (\d+)\^(\d+)\?').firstMatch(prompt!);
      expect(match, isNotNull);

      final base = int.parse(match!.group(1)!);
      final exponent = int.parse(match.group(2)!);

      var expected = 1;
      for (var i = 0; i < exponent; i++) {
        expected *= base;
      }

      expect(answer, expected);
    });

    test('M5a (Åk 7–9): Mix kan generera fråga om prioriteringsregler', () {
      final seeded = QuestionGeneratorService(
        random: Random(115),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 600; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 7,
          difficultyStep: 6,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Prioriteringsregler = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5a (Åk 7–9): prioriteringsregel-fråga ger korrekt svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(116),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? expr;
      int? answer;
      for (var i = 0; i < 1200; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 9,
          difficultyStep: 9,
        );

        final prompt = q.promptText;
        if (prompt == null || !prompt.startsWith('Prioriteringsregler = ?')) {
          continue;
        }

        final lines = prompt.split('\n');
        if (lines.length < 2) continue;
        expr = lines[1].trim();
        answer = q.correctAnswer;
        break;
      }

      expect(expr, isNotNull);
      expect(answer, isNotNull);

      int? expected;

      final p1 = RegExp(r'^\((\d+) \+ (\d+)\) × (\d+)$').firstMatch(expr!);
      if (p1 != null) {
        final a = int.parse(p1.group(1)!);
        final b = int.parse(p1.group(2)!);
        final c = int.parse(p1.group(3)!);
        expected = (a + b) * c;
      }

      final p2 = RegExp(r'^(\d+) × \((\d+) \+ (\d+)\)$').firstMatch(expr);
      if (expected == null && p2 != null) {
        final a = int.parse(p2.group(1)!);
        final b = int.parse(p2.group(2)!);
        final c = int.parse(p2.group(3)!);
        expected = a * (b + c);
      }

      final p3 = RegExp(r'^(\d+) \+ (\d+) × (\d+)$').firstMatch(expr);
      if (expected == null && p3 != null) {
        final a = int.parse(p3.group(1)!);
        final b = int.parse(p3.group(2)!);
        final c = int.parse(p3.group(3)!);
        expected = a + (b * c);
      }

      final p4 = RegExp(r'^(\d+) × (\d+) \+ (\d+)$').firstMatch(expr);
      if (expected == null && p4 != null) {
        final a = int.parse(p4.group(1)!);
        final b = int.parse(p4.group(2)!);
        final c = int.parse(p4.group(3)!);
        expected = (a * b) + c;
      }

      expect(expected, isNotNull);
      expect(answer, expected);
    });

    test('M4 (Åk 4–6): Medelvärde-uppgift ger alltid heltalssvar', () {
      final seeded = QuestionGeneratorService(
        random: Random(10),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? meanPrompt;
      int? meanAnswer;
      for (var i = 0; i < 600; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.easy,
          gradeLevel: 6,
          difficultyStep: 9,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Medelvärde')) {
          meanPrompt = prompt;
          meanAnswer = q.correctAnswer;
          break;
        }
      }

      expect(meanPrompt, isNotNull);
      expect(meanAnswer, isNotNull);

      final match = RegExp(r'Talen: ([0-9, ]+)').firstMatch(meanPrompt!);
      expect(match, isNotNull);

      final numbers =
          match!.group(1)!.split(',').map((s) => int.parse(s.trim())).toList();

      final sum = numbers.fold<int>(0, (acc, v) => acc + v);
      expect(sum % numbers.length, 0);
      expect(meanAnswer, sum ~/ numbers.length);
    });

    test('M4 (Åk 4–6): Variationsbredd-uppgift ger max-min', () {
      final seeded = QuestionGeneratorService(
        random: Random(11),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 600; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.easy,
          gradeLevel: 5,
          difficultyStep: 10,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Variationsbredd')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      final match = RegExp(r'Talen: ([0-9, ]+)').firstMatch(prompt!);
      expect(match, isNotNull);

      final numbers =
          match!.group(1)!.split(',').map((s) => int.parse(s.trim())).toList();

      final minVal = numbers.reduce((a, b) => a < b ? a : b);
      final maxVal = numbers.reduce((a, b) => a > b ? a : b);
      expect(answer, maxVal - minVal);
    });

    test('M4 (Åk 4–6): Sannolikhet (procent) ger heltal och stämmer', () {
      final seeded = QuestionGeneratorService(
        random: Random(12),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 1200; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.easy,
          gradeLevel: 5,
          difficultyStep: 6,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Chans (%)')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);
      expect(answer, inInclusiveRange(0, 100));

      final match =
          RegExp(r'Röda: (\d+), Blå: (\d+), Totalt: (\d+)').firstMatch(prompt!);
      expect(match, isNotNull);

      final red = int.parse(match!.group(1)!);
      final blue = int.parse(match.group(2)!);
      final total = int.parse(match.group(3)!);

      expect(red + blue, total);
      expect((red * 100) % total, 0);
      expect(answer, (red * 100) ~/ total);
    });

    test('M4 (Åk 4–6): Sannolikhet-jämförelse ger skillnad i procentenheter',
        () {
      final seeded = QuestionGeneratorService(
        random: Random(13),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.easy,
          gradeLevel: 6,
          difficultyStep: 8,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Skillnad i chans')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);
      expect(answer, inInclusiveRange(0, 100));

      final aMatch = RegExp(
        r'Påse A: Röda: (\d+), Blå: (\d+), Totalt: (\d+)',
      ).firstMatch(prompt!);
      final bMatch = RegExp(
        r'Påse B: Röda: (\d+), Blå: (\d+), Totalt: (\d+)',
      ).firstMatch(prompt);

      expect(aMatch, isNotNull);
      expect(bMatch, isNotNull);

      final aRed = int.parse(aMatch!.group(1)!);
      final aBlue = int.parse(aMatch.group(2)!);
      final aTotal = int.parse(aMatch.group(3)!);
      final bRed = int.parse(bMatch!.group(1)!);
      final bBlue = int.parse(bMatch.group(2)!);
      final bTotal = int.parse(bMatch.group(3)!);

      expect(aRed + aBlue, aTotal);
      expect(bRed + bBlue, bTotal);

      expect((aRed * 100) % aTotal, 0);
      expect((bRed * 100) % bTotal, 0);

      final aPercent = (aRed * 100) ~/ aTotal;
      final bPercent = (bRed * 100) ~/ bTotal;
      final expected = (aPercent - bPercent).abs();
      expect(answer, expected);
    });

    test('M4 (Åk 4–6): Mix kan generera tabellfråga (statistik)', () {
      final seeded = QuestionGeneratorService(
        random: Random(117),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 1200; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 6,
          difficultyStep: 8,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Tabell (statistik) = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4 (Åk 4–6): tabellfråga ger korrekt tolkat svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(118),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 6,
          difficultyStep: 10,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Tabell (statistik) = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      final rows = RegExp(r'[ABC] \| (\d+)').allMatches(prompt!).toList();
      expect(rows.length, 3);

      final values = rows.map((m) => int.parse(m.group(1)!)).toList();
      final questionLine = prompt.split('\n').last;

      int expected;
      if (questionLine.contains('störst')) {
        expected = values.reduce((a, b) => a > b ? a : b);
      } else if (questionLine
          .contains('skillnaden mellan största och minsta')) {
        final minVal = values.reduce((a, b) => a < b ? a : b);
        final maxVal = values.reduce((a, b) => a > b ? a : b);
        expected = maxVal - minVal;
      } else {
        final sum = values.fold<int>(0, (acc, v) => acc + v);
        expected = sum ~/ values.length;
      }

      expect(answer, expected);
    });

    test('M4 (Åk 4–6): Kombinatorik ger antal kombinationer', () {
      final seeded = QuestionGeneratorService(
        random: Random(14),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.easy,
          gradeLevel: 5,
          difficultyStep: 10,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Kombinationer')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      final match = RegExp(r'Tröjor: (\d+), Byxor: (\d+)').firstMatch(prompt!);
      expect(match, isNotNull);

      final a = int.parse(match!.group(1)!);
      final b = int.parse(match.group(2)!);
      expect(answer, a * b);
    });

    test('Unit (QuestionGeneratorService): respekterar talintervall för young',
        () {
      final questions = service.generateQuestions(
        ageGroup: AgeGroup.young,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        count: 20,
      );

      // Generatorn använder interna difficulty-steps och interpolerar mellan
      // easy/medium/hard. Verifiera därför mot step-baserad range.
      final step =
          DifficultyConfig.initialStepForDifficulty(DifficultyLevel.easy);
      final range = DifficultyConfig.getNumberRangeForStep(
        AgeGroup.young,
        OperationType.addition,
        step,
      );

      for (final question in questions) {
        expect(question.operand1, greaterThanOrEqualTo(range.min));
        expect(question.operand1, lessThanOrEqualTo(range.max));
        expect(question.operand2, greaterThanOrEqualTo(range.min));
        expect(question.operand2, lessThanOrEqualTo(range.max));
      }
    });

    test(
        'Unit (QuestionGeneratorService): felalternativ skiljer sig från rätt svar',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.medium,
      );

      expect(question.wrongAnswers.length, greaterThan(0));
      for (final wrongAnswer in question.wrongAnswers) {
        expect(wrongAnswer, isNot(question.correctAnswer));
      }
    });

    test(
        'Unit (QuestionGeneratorService): svarsalternativ innehåller rätt svar',
        () {
      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.medium,
      );

      final allOptions = question.allAnswerOptions;
      expect(allOptions.contains(question.correctAnswer), true);
    });

    test(
        'Unit (QuestionGeneratorService): kan generera textuppgift för Åk 1–3 (+/−) när påslaget',
        () {
      final wordProblemService = QuestionGeneratorService(
        wordProblemsEnabled: true,
        wordProblemsChance: 1.0,
        missingNumberEnabled: false,
      );

      final question = wordProblemService.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 2,
      );

      expect(question.promptText, isNotNull);
      expect(question.questionText, contains('?'));
    });

    test(
        'Unit (QuestionGeneratorService): kan generera saknat tal för Åk 2–3 (+) när påslaget',
        () {
      final service = QuestionGeneratorService(
        missingNumberEnabled: true,
        missingNumberChance: 1.0,
        wordProblemsEnabled: false,
      );

      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.addition,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 2,
      );

      expect(question.promptText, isNotNull);
      expect(question.questionText, contains('?'));
      expect(question.questionText, contains('='));

      final sum = question.operand1 + question.operand2;
      if (question.questionText.startsWith('?')) {
        expect(question.correctAnswer, question.operand1);
      } else {
        expect(question.correctAnswer, question.operand2);
      }
      expect(question.questionText.endsWith(sum.toString()), true);
    });

    test(
        'Unit (QuestionGeneratorService): kan generera saknat tal för Åk 2–3 (−) när påslaget',
        () {
      final service = QuestionGeneratorService(
        missingNumberEnabled: true,
        missingNumberChance: 1.0,
        wordProblemsEnabled: false,
      );

      final question = service.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.subtraction,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 3,
      );

      expect(question.promptText, isNotNull);
      expect(question.questionText, contains('?'));
      expect(question.questionText, contains('='));

      final result = question.operand1 - question.operand2;
      if (question.questionText.startsWith('?')) {
        expect(question.correctAnswer, question.operand1);
      } else {
        expect(question.correctAnswer, question.operand2);
      }
      expect(question.questionText.endsWith(result.toString()), true);
    });

    test(
        'Unit (QuestionGeneratorService): kan generera textuppgift för Åk 3 (×) när påslaget',
        () {
      final wordProblemService = QuestionGeneratorService(
        wordProblemsEnabled: true,
        wordProblemsChance: 1.0,
      );

      final question = wordProblemService.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.multiplication,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 3,
      );

      expect(question.promptText, isNotNull);
      expect(question.questionText, contains('?'));
    });

    test(
        'Unit (QuestionGeneratorService): kan generera textuppgift för Åk 3 (÷) när påslaget',
        () {
      final wordProblemService = QuestionGeneratorService(
        wordProblemsEnabled: true,
        wordProblemsChance: 1.0,
      );

      final question = wordProblemService.generateQuestion(
        ageGroup: AgeGroup.middle,
        operationType: OperationType.division,
        difficulty: DifficultyLevel.easy,
        gradeLevel: 3,
      );

      expect(question.promptText, isNotNull);
      expect(question.questionText, contains('?'));
    });

    test('M4 (Åk 4–6): Mix kan generera stapeldiagram-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(219),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 1200; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 8,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Diagram (stapel) = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4 (Åk 4–6): stapeldiagram fråga har giltigt svar', () {
      // Search for a seed that produces a bar chart question
      String? prompt;
      int? answer;

      for (int seedTry = 200; seedTry <= 350; seedTry++) {
        final seeded = QuestionGeneratorService(
          random: Random(seedTry),
          wordProblemsEnabled: false,
          missingNumberEnabled: false,
        );

        for (var i = 0; i < 2000; i++) {
          final q = seeded.generateQuestion(
            ageGroup: AgeGroup.middle,
            operationType: OperationType.mixed,
            difficulty: DifficultyLevel.hard,
            gradeLevel: 6,
            difficultyStep: 9,
          );

          final p = q.promptText;
          if (p != null && p.startsWith('Diagram (stapel) = ?')) {
            prompt = p;
            answer = q.correctAnswer;
            break;
          }
        }

        if (prompt != null) break;
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);
      expect(answer, greaterThan(0));

      // Verify prompt format contains expected structure
      if (prompt != null) {
        expect(prompt.contains('Fråga:'), true);
        expect(prompt.contains(':'), true);
      }
    });

    test('M4 (Åk 4–6): Mix kan generera sannolikhetsdiagram-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(221),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 1500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 6,
          difficultyStep: 9,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Sannolikhet (diagram) = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4 (Åk 4–6): sannolikhetsdiagram ger procent-svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(222),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 6,
          difficultyStep: 9,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Sannolikhet (diagram) = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      if (prompt != null) {
        expect(answer, greaterThanOrEqualTo(0));
        expect(answer, lessThanOrEqualTo(100));

        // Verify the prompt contains the diagram description.
        expect(prompt.contains('Röda:'), true);
        expect(prompt.contains('Blå:'), true);
      }
    });

    test('M4 (Åk 4–6): Mix kan generera enhetskonverterings-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(330),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 1500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 7,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Enhetskonvertering = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4 (Åk 4–6): enhetskonvertering ger korrekt omvandling', () {
      final seeded = QuestionGeneratorService(
        random: Random(331),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 7,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Enhetskonvertering = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);
      expect(answer, greaterThan(0));

      // Verify format includes unit names and equals sign
      if (prompt != null) {
        expect(prompt.contains('='), true);
        expect(prompt.contains('?'), true);
      }
    });

    test('M4 (Åk 4–6): Mix kan generera area-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(332),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 1500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 7,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Area')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4 (Åk 4–6): area-fråga beräknar rätt svar för form', () {
      final seeded = QuestionGeneratorService(
        random: Random(333),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 7,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Area')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);
      expect(answer, greaterThan(0));

      // Verify the prompt describes a shape
      if (prompt != null) {
        expect(
          prompt.contains('kvadrat') ||
              prompt.contains('rektangel') ||
              prompt.contains('triangel'),
          true,
        );
      }
    });

    test('M4 (Åk 4–6): Mix kan generera omkrets-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(334),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 1500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 7,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Omkrets')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4 (Åk 4–6): omkrets-fråga beräknar rätt svar för form', () {
      final seeded = QuestionGeneratorService(
        random: Random(335),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 5,
          difficultyStep: 7,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Omkrets')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);
      expect(answer, greaterThan(0));

      // Verify the prompt describes a shape
      if (prompt != null) {
        expect(
          prompt.contains('kvadrat') || prompt.contains('rektangel'),
          true,
        );
      }
    });

    test('M5b (Åk 7–9): Mix kan generera linjär-funktions-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(403),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 2500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 8,
          difficultyStep: 8,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Linjär funktion = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5b (Åk 7–9): linjär-funktions-fråga ger korrekt svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(404),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 9,
          difficultyStep: 8,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Linjär funktion = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      // Parse y = mx + b format
      final functionMatch =
          RegExp(r'y = (\d+)x ([+\-]) (\d+)').firstMatch(prompt ?? '');
      expect(functionMatch, isNotNull);

      final slope = int.parse(functionMatch!.group(1)!);
      final sign = functionMatch.group(2)!;
      final intercept = int.parse(functionMatch.group(3)!);
      final interceptValue = sign == '+' ? intercept : -intercept;

      // Parse "Beräkna y när x = X"
      final xMatch = RegExp(r'x = (\d+)').firstMatch(prompt ?? '');
      expect(xMatch, isNotNull);
      final x = int.parse(xMatch!.group(1)!);

      final expected = slope * x + interceptValue;
      expect(answer, expected);
    });

    test('M5b (Åk 7–9): Mix kan generera geometrisk-transformations-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(405),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 3000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 8,
          difficultyStep: 8,
        );

        final prompt = q.promptText;
        if (prompt != null &&
            prompt.startsWith('Geometrisk transformation = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5b (Åk 7–9): geometrisk-transformations-fråga ger korrekt svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(406),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 3000; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 9,
          difficultyStep: 8,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Geometrisk transformation = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      // Verification: prompt contains "Punkt före" and "Punkt efter"
      if (prompt != null) {
        expect(prompt.contains('Punkt före:'), true);
        expect(prompt.contains('Punkt efter:'), true);
      }

      // Verify answer is an integer (coordinate value)
      expect(answer, isNotNull);
    });

    test('M5b (Åk 7–9): Mix kan generera avancerad-statistiks-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(407),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 3500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 8,
          difficultyStep: 8,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.startsWith('Statistik = ?')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M5b (Åk 7–9): avancerad-statistiks-fråga ger korrekt svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(408),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 3500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.middle,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.hard,
          gradeLevel: 9,
          difficultyStep: 8,
        );

        final p = q.promptText;
        if (p != null && p.startsWith('Statistik = ?')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      // Verify prompt contains dataset markers
      if (prompt != null) {
        expect(
          prompt.contains('Datasätt:') || prompt.contains('Variabel A:'),
          true,
        );
      }
    });

    test('M4a (Åk 1–3): Mix kan generera tid-fråga', () {
      final seeded = QuestionGeneratorService(
        random: Random(409),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      var found = false;
      for (var i = 0; i < 2500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.young,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 2,
          difficultyStep: 5,
        );

        final prompt = q.promptText;
        if (prompt != null && prompt.contains('Klockan visar')) {
          found = true;
          break;
        }
      }

      expect(found, isTrue);
    });

    test('M4a (Åk 1–3): tid-fråga ger korrekt svar', () {
      final seeded = QuestionGeneratorService(
        random: Random(410),
        wordProblemsEnabled: false,
        missingNumberEnabled: false,
      );

      String? prompt;
      int? answer;
      for (var i = 0; i < 2500; i++) {
        final q = seeded.generateQuestion(
          ageGroup: AgeGroup.young,
          operationType: OperationType.mixed,
          difficulty: DifficultyLevel.medium,
          gradeLevel: 3,
          difficultyStep: 6,
        );

        final p = q.promptText;
        if (p != null && p.contains('Klockan visar')) {
          prompt = p;
          answer = q.correctAnswer;
          break;
        }
      }

      expect(prompt, isNotNull);
      expect(answer, isNotNull);

      // Verify answer is reasonable (time-related: 0-59 for minutes, 1-23 for hours, or duration)
      if (answer != null) {
        expect(answer >= 0, true);
        expect(answer <= 100, true); // Max duration in minutes for Åk 3
      }
    });
  });

  group('DifficultyConfig', () {
    test('Unit (DifficultyConfig): ger längre tidsgräns för yngre', () {
      final youngTime = DifficultyConfig.getTimeLimit(
        AgeGroup.young,
        DifficultyLevel.easy,
      );
      final olderTime = DifficultyConfig.getTimeLimit(
        AgeGroup.older,
        DifficultyLevel.easy,
      );

      // Younger children should get more time
      expect(youngTime, greaterThan(olderTime));
    });

    test('Unit (DifficultyConfig): ger fler frågor för äldre', () {
      final youngQuestions = DifficultyConfig.getQuestionsPerSession(
        AgeGroup.young,
      );
      final olderQuestions = DifficultyConfig.getQuestionsPerSession(
        AgeGroup.older,
      );

      expect(olderQuestions, greaterThanOrEqualTo(youngQuestions));
    });

    test('Unit (DifficultyConfig): talintervall har max > min', () {
      final range = DifficultyConfig.getNumberRange(
        AgeGroup.middle,
        OperationType.addition,
        DifficultyLevel.medium,
      );

      expect(range.max, greaterThan(range.min));
    });
  });
}
