import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/subject_model.dart';

void main() {
  group('SubjectModel', () {
    test('should create SubjectModel from constructor', () {
      const subject = SubjectModel(
        key: 'math',
        displayName: 'Mathematics',
        emoji: '📐',
        sortOrder: 1,
      );

      expect(subject.key, 'math');
      expect(subject.displayName, 'Mathematics');
      expect(subject.emoji, '📐');
      expect(subject.sortOrder, 1);
    });

    test('should create SubjectModel from valid JSON', () {
      final json = {
        'key': 'science',
        'display_name': 'Science',
        'emoji': '🧪',
        'sort_order': 2,
      };

      final subject = SubjectModel.fromJson(json);

      expect(subject.key, 'science');
      expect(subject.displayName, 'Science');
      expect(subject.emoji, '🧪');
      expect(subject.sortOrder, 2);
    });

    test('should use default values when optional JSON fields are missing', () {
      final json = {
        'key': 'history',
        'display_name': 'History',
      };

      final subject = SubjectModel.fromJson(json);

      expect(subject.key, 'history');
      expect(subject.displayName, 'History');
      expect(subject.emoji, '📚'); // Default value
      expect(subject.sortOrder, 0); // Default value
    });

    test('should handle null values for optional JSON fields', () {
      final json = {
        'key': 'art',
        'display_name': 'Art',
        'emoji': null,
        'sort_order': null,
      };

      final subject = SubjectModel.fromJson(json);

      expect(subject.key, 'art');
      expect(subject.displayName, 'Art');
      expect(subject.emoji, '📚'); // Default value
      expect(subject.sortOrder, 0); // Default value
    });
  });
}
