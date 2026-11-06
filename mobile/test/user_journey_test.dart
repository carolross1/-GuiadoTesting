import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  group('Complete User Journey E2E (Section 7)', () {
    // Document Section 7 & Practice Exercise:
    // "Extend the journey to mark the task complete, log out, and verify that the login screen appears."
    testWidgets('user can sign in, create a task, complete it, and log out', (tester) async {
      // 1. Launch application
      app.main();
      await tester.pumpAndSettle();

      // 2. Fill login form
      await tester.enterText(find.byKey(const Key('email-field')), 'tester@example.test');
      await tester.enterText(find.byKey(const Key('password-field')), 'local-test-password');
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();

      // Verify home screen loaded
      expect(find.text('My Tasks'), findsOneWidget);

      // 3. Add a new task
      await tester.tap(find.byKey(const Key('add-task-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('task-title-field')), 'Check release flow');
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Verify created task is in the list
      expect(find.text('Check release flow'), findsOneWidget);

      // 4. Practice Exercise: Mark task complete
      final taskItem = find.text('Check release flow');
      expect(taskItem, findsOneWidget);
      await tester.tap(taskItem);
      await tester.pumpAndSettle();

      // 5. Practice Exercise: Log out and verify login screen appears
      final logoutButton = find.byKey(const Key('logout-button'));
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Verify returned to login screen
      expect(find.byKey(const Key('email-field')), findsOneWidget);
      expect(find.byKey(const Key('login-button')), findsOneWidget);
    });
  });
}
