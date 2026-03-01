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

      final numbers = match!
          .group(1)!
          .split(',')
          .map((s) => int.parse(s.trim()))
          .toList();

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

      final numbers = match!
          .group(1)!
          .split(',')
          .map((s) => int.parse(s.trim()))
          .toList();

      final minVal = numbers.reduce((a, b) => a < b ? a : b);
      final maxVal = numbers.reduce((a, b) => a > b ? a : b);
      expect(answer, maxVal - minVal);
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
