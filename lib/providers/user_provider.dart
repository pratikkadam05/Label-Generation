import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/excel_service.dart';

enum LoadingState { idle, loading, success, error }

class UserProvider extends ChangeNotifier {
  final LocalStorageService _localStorage = LocalStorageService();
  final ExcelService _excelService = ExcelService();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  String _searchQuery = '';
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;

  // Getters
  List<UserModel> get users => _filteredUsers.isEmpty && _searchQuery.isEmpty
      ? _users
      : _filteredUsers;
  List<UserModel> get allUsers => _users;
  String get searchQuery => _searchQuery;
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  int get totalUsers => _users.length;

  // Initialize - load data from secure storage
  Future<void> initialize() async {
    _setLoading();
    try {
      _users = await _localStorage.getAllUsers();
      _setSuccess();
    } catch (e) {
      _setError('Error loading data: $e');
    }
  }

  // Search users
  void searchUsers(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredUsers = [];
    } else {
      _filteredUsers = _localStorage.searchUsers(_users, query);
    }
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredUsers = [];
    notifyListeners();
  }

  // Add new user
  Future<bool> addUser({
    required String name,
    required String address,
    required String phone,
  }) async {
    _setLoading();

    try {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: address,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _localStorage.addUser(user);
      _users.add(user);
      _setSuccess();
      return true;
    } catch (e) {
      _setError('Error adding user: $e');
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(UserModel user) async {
    _setLoading();

    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      final success = await _localStorage.updateUser(updatedUser);

      if (success) {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = updatedUser;
        }
        _setSuccess();
        return true;
      } else {
        _setError('User not found');
        return false;
      }
    } catch (e) {
      _setError('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    _setLoading();

    try {
      final success = await _localStorage.deleteUser(userId);

      if (success) {
        _users.removeWhere((u) => u.id == userId);
        _setSuccess();
        return true;
      } else {
        _setError('User not found');
        return false;
      }
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    }
  }

  // Import from Excel
  Future<bool> importFromExcel() async {
    _setLoading();

    try {
      final importedUsers = await _excelService.importFromExcel();

      if (importedUsers == null) {
        _setSuccess();
        return false; // User cancelled
      }

      if (importedUsers.isEmpty) {
        _setError('No users found in the Excel file');
        return false;
      }

      await _localStorage.importUsers(importedUsers);
      _users.addAll(importedUsers);
      _setSuccess();
      return true;
    } catch (e) {
      _setError('Error importing: $e');
      return false;
    }
  }

  // Export to Excel
  Future<String?> exportToExcel() async {
    _setLoading();

    try {
      final filePath = await _excelService.exportToExcel(_users);
      _setSuccess();
      return filePath;
    } catch (e) {
      _setError('Error exporting: $e');
      return null;
    }
  }

  // Share Excel
  Future<void> shareExcel(String filePath) async {
    await _excelService.shareExcel(filePath);
  }

  // Clear all data
  Future<void> clearAllData() async {
    _setLoading();
    try {
      await _localStorage.clearAll();
      _users = [];
      _filteredUsers = [];
      _searchQuery = '';
      _setSuccess();
    } catch (e) {
      _setError('Error clearing data: $e');
    }
  }

  // Helper methods
  void _setLoading() {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSuccess() {
    _loadingState = LoadingState.success;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
