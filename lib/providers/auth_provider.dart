import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final bool isPremium;
  final DateTime? expiryDate;

  UserProfile({
    required this.id,
    required this.email,
    this.isPremium = false,
    this.expiryDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String email) {
    return UserProfile(
      id: map['id'] as String,
      email: email,
      isPremium: map['is_premium'] as bool? ?? false,
      expiryDate: map['expiry_date'] != null 
          ? DateTime.parse(map['expiry_date'] as String) 
          : null,
    );
  }
}

class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isPremium => profile?.isPremium ?? false;

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _supabase = Supabase.instance.client;

  @override
  AuthState build() {
    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.user;
      if (user != null) {
        _fetchProfile(user);
      } else {
        state = AuthState();
      }
    });

    return AuthState(user: _supabase.auth.currentUser);
  }

  Future<void> _fetchProfile(User user) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      state = state.copyWith(
        user: user,
        profile: UserProfile.fromMap(data, user.email ?? ''),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      // If profile doesn't exist, we might need to create it or just handle as non-premium
      state = state.copyWith(user: user, isLoading: false);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchProfile(response.user!);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        // Profile creation is usually handled by a Postgres trigger in Supabase
        state = state.copyWith(user: response.user, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
