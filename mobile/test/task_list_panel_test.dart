import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/task_list_panel.dart';

void main() {
  group('TaskListPanel Widget Tests (Section 5)', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPanel(loading: true, tasks: []),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPanel(loading: false, tasks: []),
        ),
      );
      expect(find.text('No tasks yet.'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPanel(
            loading: false,
            tasks: [],
            errorMessage: 'Could not load tasks.',
          ),
        ),
      );
      expect(find.text('Could not load tasks.'), findsOneWidget);
    });

    testWidgets('shows task data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPanel(loading: false, tasks: ['Plan tests']),
        ),
      );
      expect(find.text('Plan tests'), findsOneWidget);
    });

    // Practice Exercise (Section 5, Page 9):
    // "Add a retry button to the error state and test that tapping it invokes a callback exactly once."
    testWidgets('retry button in error state invokes callback exactly once when tapped', (tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListPanel(
              loading: false,
              tasks: const [],
              errorMessage: 'Could not load tasks.',
              onRetry: () {
                retryCount++;
              },
            ),
          ),
        ),
      );

      // Verify retry button is rendered
      final retryButton = find.byKey(const Key('retry-button'));
      expect(retryButton, findsOneWidget);
      expect(retryCount, 0);

      // Tap retry button
      await tester.tap(retryButton);
      await tester.pump();

      // Verify callback was called exactly once
      expect(retryCount, 1);
    });
  });
}
