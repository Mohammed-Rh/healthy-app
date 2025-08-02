import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        _userModel = await _authService.getUserData(_user!.uid);
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Register
  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Update user allergies
  Future<void> updateAllergies(List<String> allergies) async {
    if (_user == null) return;

    _setLoading(true);
    try {
      await _authService.updateUserAllergies(_user!.uid, allergies);
      // Reload user data to get updated allergies
      await _loadUserData();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified {
    return _authService.isEmailVerified;
  }

  // Check email verification status
  Future<void> checkEmailVerification() async {
    try {
      await _authService.reloadUser();
      notifyListeners();
    } catch (e) {
      // Silently handle errors for periodic checks
      debugPrint('Error checking email verification: $e');
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_user != null) {
      await _loadUserData();
      notifyListeners();
    }
  }
}
