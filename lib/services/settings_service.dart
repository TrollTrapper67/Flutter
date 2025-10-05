// lib/services/settings_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';

/// Service for managing user and admin settings with Firestore and local fallback
class SettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for settings to avoid repeated reads
  static UserSettings? _cachedUserSettings;
  static AdminSettings? _cachedAdminSettings;

  /// Save user settings to Firestore or local storage
  static Future<bool> saveUserSettings(UserSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try Firestore first
      try {
        await _firestore
            .collection('settings')
            .doc('users')
            .collection('user_settings')
            .doc(user.uid)
            .set(settings.toJson());
        
        _cachedUserSettings = settings;
        return true;
      } catch (e) {
        debugPrint('Firestore save failed, falling back to local storage: $e');
        // Fallback to local storage
        return await _saveUserSettingsLocally(settings);
      }
    } catch (e) {
      debugPrint('Error saving user settings: $e');
      return false;
    }
  }

  /// Load user settings from Firestore or local storage
  static Future<UserSettings> loadUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Return cached settings if available
      if (_cachedUserSettings != null) {
        return _cachedUserSettings!;
      }

      // Try Firestore first
      try {
        final doc = await _firestore
            .collection('settings')
            .doc('users')
            .collection('user_settings')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final settings = UserSettings.fromJson(doc.data()!);
          _cachedUserSettings = settings;
          return settings;
        }
      } catch (e) {
        debugPrint('Firestore load failed, falling back to local storage: $e');
      }

      // Fallback to local storage
      return await _loadUserSettingsLocally();
    } catch (e) {
      debugPrint('Error loading user settings: $e');
      return SettingsDefaults.getDefaultUserSettings();
    }
  }

  /// Save admin settings to Firestore or local storage
  static Future<bool> saveAdminSettings(AdminSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try Firestore first
      try {
        await _firestore
            .collection('settings')
            .doc('admin')
            .collection('admin_settings')
            .doc('main')
            .set(settings.toJson());
        
        _cachedAdminSettings = settings;
        return true;
      } catch (e) {
        debugPrint('Firestore save failed, falling back to local storage: $e');
        // Fallback to local storage
        return await _saveAdminSettingsLocally(settings);
      }
    } catch (e) {
      debugPrint('Error saving admin settings: $e');
      return false;
    }
  }

  /// Load admin settings from Firestore or local storage
  static Future<AdminSettings> loadAdminSettings() async {
    try {
      // Return cached settings if available
      if (_cachedAdminSettings != null) {
        return _cachedAdminSettings!;
      }

      // Try Firestore first
      try {
        final doc = await _firestore
            .collection('settings')
            .doc('admin')
            .collection('admin_settings')
            .doc('main')
            .get();

        if (doc.exists && doc.data() != null) {
          final settings = AdminSettings.fromJson(doc.data()!);
          _cachedAdminSettings = settings;
          return settings;
        }
      } catch (e) {
        debugPrint('Firestore load failed, falling back to local storage: $e');
      }

      // Fallback to local storage
      return await _loadAdminSettingsLocally();
    } catch (e) {
      debugPrint('Error loading admin settings: $e');
      return SettingsDefaults.getDefaultAdminSettings();
    }
  }

  /// Check if user is admin (client-side check - server-side enforcement required)
  static Future<bool> isUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Try to get admin role from Firestore
      try {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data();
          return data?['role'] == 'admin' || data?['isAdmin'] == true;
        }
      } catch (e) {
        debugPrint('Error checking admin status: $e');
      }

      // Fallback: check local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isAdmin') ?? false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Seed default settings to Firestore (call this once during app initialization)
  static Future<void> seedDefaultSettings() async {
    try {
      // Seed user settings defaults
      final userDefaults = SettingsDefaults.getDefaultUserSettings();
      await _firestore
          .collection('settings')
          .doc('users')
          .collection('user_settings')
          .doc('defaults')
          .set(userDefaults.toJson());

      // Seed admin settings defaults
      final adminDefaults = SettingsDefaults.getDefaultAdminSettings();
      await _firestore
          .collection('settings')
          .doc('admin')
          .collection('admin_settings')
          .doc('defaults')
          .set(adminDefaults.toJson());

      debugPrint('Default settings seeded successfully');
    } catch (e) {
      debugPrint('Error seeding default settings: $e');
    }
  }

  /// Clear cached settings (useful for logout)
  static void clearCache() {
    _cachedUserSettings = null;
    _cachedAdminSettings = null;
  }

  // Private methods for local storage fallback

  static Future<bool> _saveUserSettingsLocally(UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString('user_settings', jsonString);
      _cachedUserSettings = settings;
      return true;
    } catch (e) {
      debugPrint('Error saving user settings locally: $e');
      return false;
    }
  }

  static Future<UserSettings> _loadUserSettingsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user_settings');
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        final settings = UserSettings.fromJson(json);
        _cachedUserSettings = settings;
        return settings;
      }
    } catch (e) {
      debugPrint('Error loading user settings locally: $e');
    }
    
    return SettingsDefaults.getDefaultUserSettings();
  }

  static Future<bool> _saveAdminSettingsLocally(AdminSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString('admin_settings', jsonString);
      _cachedAdminSettings = settings;
      return true;
    } catch (e) {
      debugPrint('Error saving admin settings locally: $e');
      return false;
    }
  }

  static Future<AdminSettings> _loadAdminSettingsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('admin_settings');
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        final settings = AdminSettings.fromJson(json);
        _cachedAdminSettings = settings;
        return settings;
      }
    } catch (e) {
      debugPrint('Error loading admin settings locally: $e');
    }
    
    return SettingsDefaults.getDefaultAdminSettings();
  }
}
