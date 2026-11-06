import 'package:flutter/material.dart';
import 'api_service.dart';
import 'task.dart';
import 'task_list_panel.dart';

// Global API service instance (can be overridden with MockApiService for tests)
ApiService apiService = MockApiService();

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager QA Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isLoggedIn = false;
  String _userEmail = '';

  void _onLoginSuccess(String email) {
    setState(() {
      _isLoggedIn = true;
      _userEmail = email;
    });
  }

  void _onLogout() async {
    await apiService.logout();
    setState(() {
      _isLoggedIn = false;
      _userEmail = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }
    return TasksHomeScreen(userEmail: _userEmail, onLogout: _onLogout);
  }
}

// -------------------------------------------------------------
// 1. LOGIN SCREEN (Keys: email-field, password-field, login-button)
// -------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});
  final ValueChanged<String> onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'tester@example.test');
  final _passwordController = TextEditingController(text: 'local-test-password');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email and password cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await apiService.login(email, password);
      if (success && mounted) {
        widget.onLoginSuccess(email);
      } else if (mounted) {
        setState(() => _errorMessage = 'Invalid credentials.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error connecting to API');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager - Sign In'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.task_alt, size: 72, color: Colors.indigo),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Email address field',
                  child: TextField(
                    key: const Key('email-field'),
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Password field',
                  child: TextField(
                    key: const Key('password-field'),
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Semantics(
                        button: true,
                        label: 'Log in to application',
                        child: ElevatedButton(
                          key: const Key('login-button'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleLogin,
                          child: const Text('Sign In', style: TextStyle(fontSize: 16)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. TASKS HOME SCREEN (Task Management + Testing Guide Panel)
// -------------------------------------------------------------
class TasksHomeScreen extends StatefulWidget {
  const TasksHomeScreen({
    super.key,
    required this.userEmail,
    required this.onLogout,
  });

  final String userEmail;
  final VoidCallback onLogout;

  @override
  State<TasksHomeScreen> createState() => _TasksHomeScreenState();
}

class _TasksHomeScreenState extends State<TasksHomeScreen> {
  List<Task> _tasks = [];
  bool _loading = false;
  String? _errorMessage;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await apiService.fetchTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load tasks.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    String? validationMsg;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('task-title-field'),
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      errorText: validationMsg,
                      hintText: 'e.g. Check release flow',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const Key('save-task-button'),
                  onPressed: () async {
                    final raw = titleController.text;
                    if (raw.trim().isEmpty) {
                      setDialogState(() {
                        validationMsg = 'Enter a valid title.';
                      });
                      return;
                    }
                    if (raw.trim().length > 120) {
                      setDialogState(() {
                        validationMsg = 'Title exceeds 120 characters.';
                      });
                      return;
                    }

                    try {
                      final created = await apiService.createTask(raw.trim());
                      setState(() {
                        _tasks.add(created);
                      });
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } catch (e) {
                      setDialogState(() {
                        validationMsg = e.toString().replaceAll('Exception: ', '');
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleTaskComplete(int index) async {
    final task = _tasks[index];
    final updated = await apiService.updateTask(task.id, completed: !task.completed);
    setState(() {
      _tasks[index] = updated;
    });
  }

  Future<void> _deleteTask(int index) async {
    final task = _tasks[index];
    await apiService.deleteTask(task.id);
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTabIndex == 0 ? 'My Tasks' : 'Testing Lab & Exercises'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            key: const Key('logout-button'),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: _currentTabIndex == 0 ? _buildTaskListView() : const ExercisesGuideViewer(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: 'Task Manager',
          ),
          NavigationDestination(
            icon: Icon(Icons.science),
            label: 'Exercises & QA Suite',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              key: const Key('add-task-button'),
              onPressed: _showAddTaskDialog,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTaskListView() {
    return TaskListPanel(
      loading: _loading,
      tasks: _tasks.map((t) => t.title).toList(),
      errorMessage: _errorMessage,
      onRetry: _loadTasks,
      onToggleTask: _toggleTaskComplete,
      onDeleteTask: _deleteTask,
    );
  }
}

// -------------------------------------------------------------
// 3. TESTING LAB & EXERCISES VIEWER (All 15 exercises from Guide)
// -------------------------------------------------------------
class ExercisesGuideViewer extends StatelessWidget {
  const ExercisesGuideViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          number: '1',
          title: 'Tester Mindset & Acceptance Criteria',
          description: 'Three acceptance criteria for Task Creation:\n'
              '1. Success: A task with a valid title (1-120 chars) is saved and displayed.\n'
              '2. Invalid input: A title containing only whitespace is rejected.\n'
              '3. Permission boundary: User cannot access or tamper with another user’s task.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Bug Report: Task disappears after completion',
          description: '• Summary: Task marked completed disappears from view instead of updating status.\n'
              '• Steps: 1. Sign in. 2. Create task. 3. Tap complete button.\n'
              '• Expected: Task shown with completed strike-through style.\n'
              '• Actual: Task is hidden/deleted from the list view.\n'
              '• Severity: High (data loss perception) | Priority: High (core feature).',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Exploratory Charter & Session Notes',
          description: 'Charter: "Explore task creation and editing to find data-loss problems in 15 mins."\n'
              '• 00:00 - Normal title: Saved OK.\n'
              '• 00:05 - Title with 120 chars: Saved OK.\n'
              '• 00:08 - Rapid repeated taps on Save: Prevented duplicate task creation.\n'
              '• 00:12 - Network offline during save: Safe error shown, title preserved in draft.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Unit Tests in Isolation (Jest & Flutter)',
          description: '• Backend Jest: validateTitle() trims whitespace, rejects blank title, allows up to 120 characters.\n'
              '• Dart/Flutter: Task.fromJson() validates required string id and non-empty title, throws FormatException on invalid data.',
        ),
        _buildSectionCard(
          number: '5',
          title: 'Flutter Widget Testing & Retry Button',
          description: '• Verified states: loading (CircularProgressIndicator), empty (No tasks yet), data, and error.\n'
              '• Practice exercise: Added retry button in error state, verified with testWidgets that tapping it triggers callback exactly once.',
        ),
        _buildSectionCard(
          number: '6',
          title: 'API & Integration Testing (Supertest)',
          description: '• Covered routes: /api/v1/tasks (CRUD & Security).\n'
              '• Verified 401 on unauthenticated access.\n'
              '• Verified 404/403 consistent policy preventing enumeration of foreign tasks.',
        ),
        _buildSectionCard(
          number: '7',
          title: 'Complete User Journey (E2E Integration Test)',
          description: '• Test flow: Sign in -> Add Task -> Check Release Flow -> Complete Task -> Log Out -> Verify Login Screen.',
        ),
        _buildSectionCard(
          number: '8',
          title: 'Boundary Value & Equivalence Partitioning (Password)',
          description: 'Password rules (min 8, max 64):\n'
              '• Empty (""): Reject\n'
              '• Below min (7 chars "abc1234"): Reject\n'
              '• Min boundary (8 chars "abc12345"): Accept\n'
              '• Typical (14 chars "Safe#P@ss2026"): Accept\n'
              '• Max boundary (64 chars): Accept\n'
              '• Over max (65 chars): Reject.',
        ),
        _buildSectionCard(
          number: '9',
          title: 'Security Basics & OWASP API Top 10',
          description: '• Mass assignment test: Client sending ownerId parameter is ignored/rejected by backend.\n'
              '• SQL Injection payload (\' OR \'1\'=\'1) treated as literal text.\n'
              '• XSS payload (<script>alert(1)</script>) safely stored and rendered as plain text.',
        ),
        _buildSectionCard(
          number: '10',
          title: 'Performance & Load Testing (k6)',
          description: '• k6 script configured with 5 VUs for 30s against /health.\n'
              '• Thresholds: rate < 0.01 (error rate < 1%), p(95) < 500ms.\n'
              '• Changing threshold to p(95) < 50ms evaluates whether API breaches strict latency bounds under load.',
        ),
        _buildSectionCard(
          number: '11',
          title: 'Usability & Accessibility (A11y)',
          description: '• Semantic labels on form fields and buttons.\n'
              '• Large font scale (1.5x) support without text clipping.\n'
              '• High contrast color scheme conforming to WCAG AA.',
        ),
        _buildSectionCard(
          number: '12',
          title: 'Device & Platform Compatibility Matrix',
          description: '• Android Small Screen (min SDK): Verified font scaling & touch targets.\n'
              '• Android Mainstream: Verified CRUD & token refresh.\n'
              '• iOS Small & Mainstream: Verified secure session & navigation.\n'
              '• Emulators/Simulators: Automated smoke test target.',
        ),
        _buildSectionCard(
          number: '13',
          title: 'Regression Checklist & Test Data Management',
          description: '• Verification matrix for task creation, editing, completion, deletion, and cross-user isolation.\n'
              '• Synthetic data isolation before each test run.',
        ),
        _buildSectionCard(
          number: '14',
          title: 'CI Automation & Coverage (GitHub Actions)',
          description: '• .github/workflows/tests.yml runs npm test (Node 22) and flutter test in parallel.\n'
              '• Fails pipeline on broken test and passes upon resolution.',
        ),
        _buildSectionCard(
          number: '15',
          title: 'Mocks vs. Real Integration Comparison',
          description: '• Mocked tests: Fast, isolated, ideal for edge cases & offline verification.\n'
              '• Real DB tests: Catches constraint violations, SQL quirks, and concurrency issues.',
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
