import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task.dart';

abstract class ApiService {
  Future<bool> login(String email, String password);
  Future<bool> register(String email, String password);
  Future<List<Task>> fetchTasks();
  Future<Task> createTask(String title);
  Future<Task> updateTask(String id, {String? title, bool? completed});
  Future<void> deleteTask(String id);
  Future<void> logout();
  bool get isAuthenticated;
}

class RemoteApiService implements ApiService {
  RemoteApiService({this.baseUrl = 'http://localhost:3000'});

  final String baseUrl;
  String? _accessToken;
  String? _refreshToken;

  @override
  bool get isAuthenticated => _accessToken != null;

  @override
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      return true;
    }
    return false;
  }

  @override
  Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      return true;
    }
    return false;
  }

  @override
  Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((item) => Task.fromJson(item)).toList();
    } else {
      throw Exception('Could not load tasks.');
    }
  }

  @override
  Future<Task> createTask(String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to create task';
      throw Exception(error);
    }
  }

  @override
  Future<Task> updateTask(String id, {String? title, bool? completed}) async {
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (completed != null) body['completed'] = completed;

    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/tasks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update task');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/tasks/$id'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  @override
  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/api/v1/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': _refreshToken}),
        );
      } catch (_) {}
    }
    _accessToken = null;
    _refreshToken = null;
  }
}

/// In-memory mock API service used for deterministic UI & integration tests (Exercise 15)
class MockApiService implements ApiService {
  final List<Task> _tasks = [];
  bool _authenticated = false;
  int _counter = 1;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<bool> login(String email, String password) async {
    _authenticated = true;
    return true;
  }

  @override
  Future<bool> register(String email, String password) async {
    _authenticated = true;
    return true;
  }

  @override
  Future<List<Task>> fetchTasks() async {
    return List.from(_tasks);
  }

  @override
  Future<Task> createTask(String title) async {
    if (title.trim().isEmpty) {
      throw Exception('Enter a valid title.');
    }
    final task = Task(id: 'task-${_counter++}', title: title.trim());
    _tasks.add(task);
    return task;
  }

  @override
  Future<Task> updateTask(String id, {String? title, bool? completed}) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('Task not found');
    final current = _tasks[index];
    final updated = current.copyWith(
      title: title ?? current.title,
      completed: completed ?? current.completed,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> logout() async {
    _authenticated = false;
  }
}
