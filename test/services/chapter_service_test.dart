import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/services/chapter_service.dart';

void main() {
  group('ChapterService', () {
    group('getChapters', () {
      test('should return correct chapters for a valid subject key', () {
        final physicsChapters = ChapterService.getChapters('physics');
        expect(physicsChapters, isNotEmpty);
        expect(physicsChapters.first, contains('ভৌত রাশি'));

        final mathChapters = ChapterService.getChapters('general math');
        expect(mathChapters, isNotEmpty);
        expect(mathChapters.first, contains('বাস্তব সংখ্যা'));
      });

      test('should be case-insensitive and trim whitespace', () {
        final physicsChapters = ChapterService.getChapters('  PHYSICS  ');
        expect(physicsChapters, isNotEmpty);
        expect(physicsChapters.first, contains('ভৌত রাশি'));
      });

      test('should return an empty list when the subject key is not found', () {
        final unknownChapters = ChapterService.getChapters('unknown subject');
        expect(unknownChapters, isEmpty);
      });

      test('should return an empty list when the subject key is null', () {
        final chapters = ChapterService.getChapters(null);
        expect(chapters, isEmpty);
      });

      test('should handle keys with special characters like & or -', () {
        final specialChapters = ChapterService.getChapters('science & math');
        expect(specialChapters, isEmpty);

        final hyphenChapters = ChapterService.getChapters('test-subject');
        expect(hyphenChapters, isEmpty);
      });
    });

    group('hasChapters', () {
      test('should return true for a valid subject key', () {
        expect(ChapterService.hasChapters('physics'), isTrue);
        expect(ChapterService.hasChapters('ICT'), isTrue);
      });

      test('should be case-insensitive and trim whitespace', () {
        expect(ChapterService.hasChapters('  BIOLOGY  '), isTrue);
      });

      test('should return false when the subject key is not found', () {
        expect(ChapterService.hasChapters('nonexistent'), isFalse);
      });

      test('should return false when the subject key is null', () {
        final result = ChapterService.hasChapters(null);
        expect(result, isFalse);
      });
    });

    group('Specific Subject Content', () {
      test('should return 5 chapters for islam', () {
        final chapters = ChapterService.getChapters('islam');
        expect(chapters.length, 5);
        expect(chapters.first, contains('আকাইদ ও নৈতিক জীবন'));
      });

      test('should return 16 chapters for english 1st', () {
        final chapters = ChapterService.getChapters('english 1st');
        expect(chapters.length, 16);
        expect(chapters.first, equals('1. Sense of Self'));
      });

      test('should return 43 chapters for bangla 2nd', () {
        final chapters = ChapterService.getChapters('bangla 2nd');
        expect(chapters.length, 43);
        expect(chapters.first, equals('১. ভাষা ও বাংলা ভাষা'));
      });
    });
  });
}
