// services/auth_service.dart
import '../models/user.dart';

class AuthService {
  static List<User> _users = []; // In-memory user storage
  static User? _currentUser; // Currently logged in user

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validation
    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'All fields are required',
      };
    }

    if (!email.contains('@')) {
      return {
        'success': false,
        'message': 'Invalid email format',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // Check if email already exists
    final existingUser = _users.where((user) => user.email == email).firstOrNull;
    if (existingUser != null) {
      return {
        'success': false,
        'message': 'Email already registered',
      };
    }

    // Create new user
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      password: password,
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    _currentUser = newUser;

    return {
      'success': true,
      'message': 'Registration successful',
      'user': newUser,
    };
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validation
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email and password are required',
      };
    }

    // Find user
    final user = _users.where((user) => user.email == email).firstOrNull;

    if (user == null) {
      return {
        'success': false,
        'message': 'User not found',
      };
    }

    if (user.password != password) {
      return {
        'success': false,
        'message': 'Incorrect password',
      };
    }

    _currentUser = user;

    return {
      'success': true,
      'message': 'Login successful',
      'user': user,
    };
  }

  // Logout
  static Future<void> logout() async {
    _currentUser = null;
  }

  // Get current user
  static User? getCurrentUser() {
    return _currentUser;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return _currentUser != null;
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
  }) async {
    if (_currentUser == null) {
      return {
        'success': false,
        'message': 'No user logged in',
      };
    }

    // Find and update user in list
    final index = _users.indexWhere((user) => user.id == _currentUser!.id);
    if (index != -1) {
      final updatedUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: name,
        password: _currentUser!.password,
        createdAt: _currentUser!.createdAt,
      );

      _users[index] = updatedUser;
      _currentUser = updatedUser;

      return {
        'success': true,
        'message': 'Profile updated',
        'user': updatedUser,
      };
    }

    return {
      'success': false,
      'message': 'Failed to update profile',
    };
  }

  // Delete account
  static Future<void> deleteAccount() async {
    if (_currentUser != null) {
      _users.removeWhere((user) => user.id == _currentUser!.id);
      _currentUser = null;
    }
  }

  // Get all users (for testing)
  static List<User> getAllUsers() {
    return List.from(_users);
  }
}