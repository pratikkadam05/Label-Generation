import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _usersKey = 'users_data';

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    final data = await _storage.read(key: _usersKey);
    if (data == null || data.isEmpty) return [];

    final jsonList = jsonDecode(data) as List;
    return jsonList.map((json) => UserModel.fromJson(json)).toList();
  }

  // Save all users
  Future<void> saveAllUsers(List<UserModel> users) async {
    final jsonList = users.map((u) => u.toJson()).toList();
    await _storage.write(key: _usersKey, value: jsonEncode(jsonList));
  }

  // Add a user
  Future<void> addUser(UserModel user) async {
    final users = await getAllUsers();
    users.add(user);
    await saveAllUsers(users);
  }

  // Update a user
  Future<bool> updateUser(UserModel user) async {
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index == -1) return false;

    users[index] = user;
    await saveAllUsers(users);
    return true;
  }

  // Delete a user
  Future<bool> deleteUser(String id) async {
    final users = await getAllUsers();
    final initialLength = users.length;
    users.removeWhere((u) => u.id == id);

    if (users.length == initialLength) return false;

    await saveAllUsers(users);
    return true;
  }

  // Search users locally
  List<UserModel> searchUsers(List<UserModel> users, String query) {
    if (query.isEmpty) return users;

    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
          user.address.toLowerCase().contains(lowerQuery) ||
          user.phone.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Import users (add to existing)
  Future<void> importUsers(List<UserModel> newUsers) async {
    final existingUsers = await getAllUsers();
    existingUsers.addAll(newUsers);
    await saveAllUsers(existingUsers);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.delete(key: _usersKey);
  }
}
