import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/api_service.dart';

void main() {
  group('Mock vs Real API Test Comparison (Section 15)', () {
    test('Mocked API Client test - Fast and deterministic', () async {
      final mockApi = MockApiService();

      final loggedIn = await mockApi.login('test@example.com', 'secret');
      expect(loggedIn, isTrue);

      final task = await mockApi.createTask('Mocked deterministic title');
      expect(task.title, 'Mocked deterministic title');

      final tasks = await mockApi.fetchTasks();
      expect(tasks.length, 1);

      // What this catches: Client parsing logic, app state transitions, happy paths.
      // What this cannot catch: Network failures, HTTP status mismatches, database constraint violations.
    });
  });
}
