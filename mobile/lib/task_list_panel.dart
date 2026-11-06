import 'package:flutter/material.dart';

/// Shows tasks or the current loading, empty, or error state.
class TaskListPanel extends StatelessWidget {
  /// Creates a task list panel.
  const TaskListPanel({
    super.key,
    required this.loading,
    required this.tasks,
    this.errorMessage,
    this.onRetry,
    this.onToggleTask,
    this.onDeleteTask,
  });

  /// Whether tasks are being loaded.
  final bool loading;

  /// Task titles to display.
  final List<String> tasks;

  /// Optional safe error message.
  final String? errorMessage;

  /// Practice exercise (Section 5, Page 9):
  /// Callback invoked when user taps retry button in error state.
  final VoidCallback? onRetry;

  /// Optional callbacks for interaction
  final ValueChanged<int>? onToggleTask;
  final ValueChanged<int>? onDeleteTask;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 12),
              // Practice exercise: Retry button in error state
              ElevatedButton.icon(
                key: const Key('retry-button'),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: ListView.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final taskTitle = tasks[index];
          return ListTile(
            key: Key('task-item-$index'),
            leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
            title: Text(taskTitle),
            trailing: onDeleteTask != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => onDeleteTask?.call(index),
                  )
                : null,
            onTap: () => onToggleTask?.call(index),
          );
        },
      ),
    );
  }
}
