import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if username is unique
  Future<bool> isUsernameUnique(String username) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim().toLowerCase())
          .get();
      return result.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking username uniqueness: $e');
      return false; // Assume not unique on error for safety
    }
  }

  // 2. Email/Password Sign Up - COMPLETELY SAFE VERSION
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String mobile,
    required String username,
    required String userType, // 'user' or 'service_provider'
  }) async {
    try {
      // 1. VALIDATE INPUTS BEFORE ANY FIREBASE CALL
      _validateSignUpInputs(email, password, mobile, userType, username: username);

      // Check username uniqueness again before proceeding
      bool isUnique = await isUsernameUnique(username);
      if (!isUnique) {
        throw Exception('Username is already taken');
      }

      // 2. CREATE USER IN FIREBASE AUTH (FIRST STEP)
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw _handleFirebaseAuthError(e);
      }

      // 3. VERIFY USER WAS CREATED SUCCESSFULLY
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // 4. PREPARE USER DATA FOR FIRESTORE
      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': email.trim(),
        'mobile': mobile.trim(),
        'username': username.trim().toLowerCase(),
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        // 'accountStatus': 'active',
        // 'profileComplete': false,
      };

      // 5. STORE USER DATA IN FIRESTORE (ATOMIC OPERATION)
      try {
        await _firestore.runTransaction((transaction) async {
          // Create document reference
          final DocumentReference userDocRef =
          _firestore.collection('users').doc(user.uid);

          // Check if document already exists (shouldn't for new user)
          final DocumentSnapshot docSnapshot = await transaction.get(userDocRef);
          if (docSnapshot.exists) {
            throw Exception('User document already exists');
          }

          // Set the document with transaction
          transaction.set(userDocRef, userData);
        });

        print('✅ User created successfully in Auth & Firestore');
        print('📱 User ID: ${user.uid}');
        print('📧 Email: ${user.email}');
        print('👤 Username: $username');
        print('👤 User Type: $userType');

        return user;
      } catch (firestoreError) {
        // 6. FIRESTORE FAILED - ROLLBACK AUTH USER CREATION
        print('⚠️ Firestore failed, rolling back Auth user...');
        try {
          await user.delete();
          print('✅ Rollback successful: Auth user deleted');
        } catch (deleteError) {
          print('❌ Failed to rollback Auth user: $deleteError');
          // Don't throw here, we want to show the original Firestore error
        }

        // Re-throw the Firestore error
        throw Exception('Failed to store user data: $firestoreError');
      }

    } catch (e) {
      // 7. HANDLE ALL OTHER ERRORS
      print('❌ Sign up failed: $e');
      rethrow;
    }
  }


  // 3. Email/Password Sign In - SAFE VERSION
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs first
      if (email.isEmpty) throw Exception('Email is required');
      if (password.isEmpty) throw Exception('Password is required');

      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address');
      }

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw _handleFirebaseAuthError(e);
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Verify user exists in Firestore
      final userExists = await userExistsInFirestore(user.uid);
      if (!userExists) {
        // User exists in Auth but not in Firestore - create basic record
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'userType': 'user', // Default type
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
        }, SetOptions(merge: true));

        print('⚠️ Created missing Firestore record for user: ${user.uid}');
      } else {
        // Update last login timestamp
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print('❌ Sign in failed: $e');
      rethrow;
    }
  }

  // 4. Validation method for signup inputs
  void _validateSignUpInputs(
      String email,
      String password,
      String mobile,
      String userType,
      {String? username}
      ) {
    // Username validation if provided
    if (username != null) {
      if (username.isEmpty) {
        throw Exception('Username is required');
      }
      if (username.length < 3) {
        throw Exception('Username must be at least 3 characters long');
      }
      final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
      if (!usernameRegex.hasMatch(username)) {
        throw Exception('Username can only contain letters, numbers, and underscores');
      }
    }

    // Email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      throw Exception('Email is required');
    }
    if (!emailRegex.hasMatch(email.trim())) {
      throw Exception('Please enter a valid email address');
    }

    // Password validation
    if (password.isEmpty) {
      throw Exception('Password is required');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    // Mobile validation (basic)
    if (mobile.isEmpty) {
      throw Exception('Mobile number is required');
    }
    final mobileDigits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobileDigits.length < 10) {
      throw Exception('Please enter a valid mobile number');
    }

    // User type validation
    if (userType.isEmpty) {
      throw Exception('User type is required');
    }
    if (userType != 'user' && userType != 'service_provider') {
      throw Exception('Invalid user type specified');
    }
  }

  // 5. Apple Sign In - SAFE VERSION
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.example.sevashare.service',
          redirectUri: Uri.parse(
            'https://sevashare.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token is null');
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(oauthCredential);
      } on FirebaseAuthException catch (e) {
        throw _handleFirebaseAuthError(e);
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // Prepare user data
      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email ?? appleCredential.email ?? '',
        'name': '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim(),
        'userType': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'emailVerified': true,
        'authProvider': 'apple',
      };

      // Store/update in Firestore
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      print('❌ Apple Sign In failed: $e');
      throw Exception('Apple Sign In failed: ${e.toString()}');
    }
  }

  // 6. Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // await FacebookAuth.instance.logOut();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // 7. Password Reset
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) throw Exception('Email is required');

      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      print('❌ Password reset failed: $e');
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // 8. Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }

      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      await user.sendEmailVerification();
      print('✅ Verification email sent to: ${user.email}');
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      print('❌ Send verification failed: $e');
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // 10. Delete User Account - COMPLETELY SAFE
  Future<void> deleteUserAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }

      // Get user data before deletion (for rollback if needed)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // 1. Delete from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();
      print('✅ Firestore user document deleted');

      // 2. Delete from Firebase Auth
      await user.delete();
      print('✅ Auth user account deleted');

      // Optional: Archive user data for compliance
      if (userData != null) {
        await _firestore.collection('deleted_users').doc(user.uid).set({
          ...userData,
          'deletedAt': FieldValue.serverTimestamp(),
          'originalUid': user.uid,
        });
        print('✅ User data archived');
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please re-authenticate to delete your account');
      }
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      print('❌ Account deletion failed: $e');
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // 11. Check if user exists in Firestore
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      if (uid.isEmpty) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  // Enhanced Error Handler
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Contact support.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with mix of letters, numbers, and symbols.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again in 15 minutes.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Your session expired. Please sign in again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Try a different sign-in method.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Verification failed. Please try again.';
      case 'quota-exceeded':
        return 'Service temporarily unavailable. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized. Contact support.';
      case 'keychain-error':
        return 'Keychain error on iOS. Check device settings.';
      case 'internal-error':
        return 'Internal server error. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your information.';
      case 'invalid-argument':
        return 'Invalid input provided.';
      case 'missing-android-pkg-name':
        return 'Android package name is missing.';
      case 'missing-continue-uri':
        return 'Continue URL is missing.';
      case 'missing-ios-bundle-id':
        return 'iOS bundle ID is missing.';
      case 'unauthorized-domain':
        return 'Unauthorized domain for authentication.';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  // 12. Get User Data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      if (uid.isEmpty) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user data: $e');
      return null;
    }
  }

  // 13. Check if user is authenticated AND has Firestore record
  Future<bool> isUserComplete() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final exists = await userExistsInFirestore(user.uid);
      return exists;
    } catch (e) {
      print('❌ Error checking user completeness: $e');
      return false;
    }
  }
}
