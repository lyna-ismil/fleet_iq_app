import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// ─── Auth Status ───────────────────────────────────────────
enum AuthStatus { unauthenticated, loading, authenticated, suspended }

// ─── Auth State ────────────────────────────────────────────
class AuthState {
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;
  final bool isBlacklisted;
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.isBlacklisted = false,
    this.status = AuthStatus.unauthenticated,
    this.errorMessage,
  });

  const AuthState.initial()
      : userId = null,
        accessToken = null,
        refreshToken = null,
        user = null,
        isBlacklisted = false,
        status = AuthStatus.unauthenticated,
        errorMessage = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    String? userId,
    String? accessToken,
    String? refreshToken,
    UserModel? user,
    bool? isBlacklisted,
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ─── Auth Notifier ─────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Kick off session restore (async, will update state when done)
    _tryRestoreSession();
    return const AuthState.initial();
  }

  /// Decode JWT payload to extract userId
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      return {};
    }
  }

  /// Try to restore a previous session from SharedPreferences
  Future<void> _tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final userId = prefs.getString('userId');

      if (token != null && userId != null) {
        // We have a saved session — set authenticated immediately
        state = AuthState(
          userId: userId,
          accessToken: token,
          status: AuthStatus.authenticated,
        );

        // Then fetch full profile in background
        try {
          final profileData = await ApiService.getUserProfile(userId);
          state = state.copyWith(
            user: UserModel.fromJson(profileData),
          );
        } catch (e) {
          // Profile fetch failed but token is still valid
          print('⚠️ Could not refresh profile: $e');
        }
      }
    } catch (e) {
      print('⚠️ Session restore failed: $e');
    }
  }

  /// Log in with email and password
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final data = await ApiService.loginUser(email, password);

      final accessToken = data['accessToken'] as String;
      final decoded = _decodeJwt(accessToken);
      final userId = decoded['id'] as String?;

      if (userId == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Invalid token received',
        );
        return;
      }

      // Persist to SharedPreferences (for cold-start restore)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('userId', userId);

      state = AuthState(
        userId: userId,
        accessToken: accessToken,
        status: AuthStatus.authenticated,
      );

      // Fetch full user profile
      try {
        final profileData = await ApiService.getUserProfile(userId);
        final user = UserModel.fromJson(profileData);
        state = state.copyWith(
          user: user,
          isBlacklisted: user.isBlacklisted,
        );

        if (user.isBlacklisted) {
          state = state.copyWith(status: AuthStatus.suspended);
        }
      } catch (e) {
        print('⚠️ Profile fetch after login failed: $e');
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().contains('Login Failed')
            ? 'Invalid email or password.'
            : 'Server connection failed. Check your network.',
      );
    }
  }

  /// Refresh the user profile data
  Future<void> refreshUserProfile() async {
    if (state.userId == null) return;
    try {
      final profileData = await ApiService.getUserProfile(state.userId!);
      state = state.copyWith(user: UserModel.fromJson(profileData));
    } catch (e) {
      print('⚠️ Profile refresh failed: $e');
    }
  }

  /// Log out and clear all persisted state
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    state = const AuthState.initial();
  }
}

// ─── Provider ──────────────────────────────────────────────
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
