import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import "package:flutter_riverpod/legacy.dart";
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

  AuthState clearMessages() {
    return AuthState(
      user: user,
      isLoading: isLoading,
      error: null,
      successMessage: null,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      try {
        final appUser = await _authRepository.getUserData(currentUser.uid);
        if (appUser != null) {
          state = state.copyWith(user: appUser);
        }
      } catch (e) {
        await _authRepository.signOut();
      }
    }
  }

  void clearMessages() {
    state = state.clearMessages();
  }

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

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});