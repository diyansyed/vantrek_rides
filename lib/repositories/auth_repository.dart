import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['email'],
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
    required UserType userType,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Sign in failed. Please try again.';
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw 'User data not found. Please sign up first.';
      }

      final appUser = AppUser.fromMap(userDoc.data()!);

      if (appUser.userType != userType) {
        await _auth.signOut();
        throw 'Please sign in with the correct account type (${userType.name}).';
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required UserType userType,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Sign up failed. Please try again.';
      }

      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      final appUser = AppUser(
        uid: userCredential.user!.uid,
        email: email.trim(),
        displayName: displayName,
        photoUrl: null,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(appUser.uid)
          .set(appUser.toMap());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<AppUser> signInWithGoogle({required UserType userType}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign-in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw 'Failed to get authentication tokens from Google.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw 'Google sign-in failed. Please try again.';
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      AppUser appUser;

      if (userDoc.exists) {
        appUser = AppUser.fromMap(userDoc.data()!);

        if (appUser.userType != userType) {
          await _auth.signOut();
          await _googleSignIn.signOut();
          throw 'Please sign in with the correct account type (${userType.name}).';
        }
      } else {
        appUser = AppUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          userType: userType,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(appUser.uid)
            .set(appUser.toMap());
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'Failed to sign out: ${e.toString()}';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data: ${e.toString()}';
    }
  }

  // Update user data
  Future<void> updateUserData(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw 'Failed to update user data: ${e.toString()}';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}