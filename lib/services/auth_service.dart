import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_helper.dart';
import 'app_state_service.dart';
import 'security_service.dart';
import 'settings_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AppStateService _appState = AppStateService();
  final SecurityService _security = SecurityService();
  final SettingsService _settings = SettingsService();

  // Auth State Stream
  Stream<User?> get user => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Clear any existing local data before signing in
      await _clearLocalData();
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear any existing local data before signing in
      await _clearLocalData();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    // Sign out immediately for quick response
    await _googleSignIn.signOut();
    await _auth.signOut();
    
    // Clear local data in background (don't await)
    // ignore: unawaited_futures
    _clearLocalData();
  }

  // Clear all local data for account isolation
  Future<void> _clearLocalData() async {
    try {
      // Clear app state cache
      _appState.clearCache();
      
      // Clear all local database data
      await _dbHelper.clearAllData();
      
      // Clear security data (PIN/passcode)
      await _security.removePasscode();
      await _security.setBiometricsEnabled(false);
      
      // Reset settings to defaults
      await _settings.setDarkMode(false);
      await _settings.setCurrency('USD');
      
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An undefined Error happened.';
    }
  }
}
