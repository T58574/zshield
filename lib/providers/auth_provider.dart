import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final bool isPremium;
  final DateTime? expiryDate;
  final String? premiumSubscriptionUrl;

  UserProfile({
    required this.id,
    required this.email,
    this.isPremium = false,
    this.expiryDate,
    this.premiumSubscriptionUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String email) {
    return UserProfile(
      id: map['id'] as String,
      email: email,
      isPremium: map['is_premium'] as bool? ?? false,
      expiryDate: map['expiry_date'] != null 
          ? DateTime.parse(map['expiry_date'] as String) 
          : null,
      premiumSubscriptionUrl: map['premium_subscription_url'] as String?,
    );
  }
}

class AuthState {
  final User? authUser;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  AuthState({
    this.authUser,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => authUser != null;
  bool get isPremium => profile?.isPremium ?? false;

  AuthState copyWith({
    User? authUser,
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      authUser: clearUser ? null : (authUser ?? this.authUser),
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
      final user = data.session?.user;
      if (user != null) {
        _fetchProfile(user);
      } else {
        state = AuthState();
      }
    });

    // Auto-login if no user
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _fetchProfile(currentUser);
    }

    return AuthState(authUser: currentUser);
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signInAnonymously();
      if (response.user != null) {
        await _fetchProfile(response.user!);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchProfile(User user) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      state = state.copyWith(
        authUser: user,
        profile: UserProfile.fromMap(data, user.email ?? ''),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      state = state.copyWith(authUser: user, isLoading: false);
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
        state = state.copyWith(authUser: response.user, isLoading: false);
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
