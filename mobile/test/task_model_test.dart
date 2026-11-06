import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/task.dart';

void main() {
  group('Task Model Tests (Section 4)', () {
    // Original examples from document (Page 6-7)
    test('parses a valid task', () {
      final task = Task.fromJson({'id': 'task-1', 'title': 'Plan tests'});
      expect(task.id, 'task-1');
      expect(task.title, 'Plan tests');
      expect(task.completed, false);
    });

    test('rejects an empty title', () {
      expect(
        () => Task.fromJson({'id': 'task-1', 'title': ' '}),
        throwsFormatException,
      );
    });

    // Practice Exercise (Section 4, Page 7):
    // "Add a unit test for a missing ID and one for a valid title at the maximum allowed length."
    test('rejects a missing ID', () {
      expect(
        () => Task.fromJson({'title': 'Plan tests'}),
        throwsFormatException,
      );
      expect(
        () => Task.fromJson({'id': null, 'title': 'Plan tests'}),
        throwsFormatException,
      );
      expect(
        () => Task.fromJson({'id': 12345, 'title': 'Plan tests'}),
        throwsFormatException,
      );
    });

    test('parses a valid title at the maximum allowed length (120 characters)', () {
      final maxTitle = 'T' * 120;
      final task = Task.fromJson({'id': 'task-max-1', 'title': maxTitle});
      expect(task.title, maxTitle);
      expect(task.title.length, 120);
    });
  });
}
