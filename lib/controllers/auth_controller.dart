import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import "package:flutter_riverpod/legacy.dart";
// Auth State
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? false,
      error: error,
      successMessage: successMessage,
    );
  }

  // Clear error and success messages
  AuthState clearMessages() {
    return AuthState(
      user: user,
      isLoading: isLoading,
      error: null,
      successMessage: null,
    );
  }
}

// Auth Controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(AuthState()) {
    // Check if user is already logged in when controller initializes
    _checkCurrentUser();
  }

  // Check if there's an existing logged-in user
  Future<void> _checkCurrentUser() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      try {
        // Get user data from Firestore
        final appUser = await _authRepository.getUserData(currentUser.uid);
        if (appUser != null) {
          state = state.copyWith(user: appUser);
        }
      } catch (e) {
        // If error fetching user data, sign out
        await _authRepository.signOut();
      }
    }
  }

  // Clear messages
  void clearMessages() {
    state = state.clearMessages();
  }

  // Sign in with email and password
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
    required UserType userType,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await _authRepository.signInWithEmailPassword(
        email: email,
        password: password,
        userType: userType,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        successMessage: 'Welcome back, ${user.displayName ?? user.email}!',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required UserType userType,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        userType: userType,
        displayName: displayName,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        successMessage: 'Account created successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle({required UserType userType}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await _authRepository.signInWithGoogle(
        userType: userType,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        successMessage: 'Signed in with Google successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset email sent. Please check your inbox.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Auth Controller Provider
final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});