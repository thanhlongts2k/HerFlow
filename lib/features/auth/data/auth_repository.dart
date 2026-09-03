// lib/features/auth/data/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Box get _userBox => Hive.box(AppConstants.userBoxName);

  /// Lấy thông tin người dùng hiện tại (từ Hive cục bộ hoặc FirebaseAuth)
  UserModel? getCurrentUser() {
    try {
      final isLoggedIn = _userBox.get(AppConstants.keyUserIsLoggedIn, defaultValue: false) as bool;
      if (!isLoggedIn) {
        final fbUser = _firebaseAuth.currentUser;
        if (fbUser != null) {
          return UserModel(
            uid: fbUser.uid,
            displayName: fbUser.displayName ?? 'Người dùng Moona',
            email: fbUser.email ?? '',
            photoUrl: fbUser.photoURL,
          );
        }
        return null;
      }

      final uid = _userBox.get(AppConstants.keyUserUid) as String?;
      if (uid == null || uid.isEmpty) return null;

      final displayName = _userBox.get(AppConstants.keyUserDisplayName) as String? ?? 'Người dùng';
      final email = _userBox.get(AppConstants.keyUserEmail) as String? ?? '';
      final photoUrl = _userBox.get(AppConstants.keyUserPhotoUrl) as String?;

      return UserModel(
        uid: uid,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
      );
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Đăng nhập bằng tài khoản Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng bấm hủy chọn tài khoản
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Không nhận được thông tin người dùng từ Firebase');
      }

      final userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? googleUser.displayName ?? 'Người dùng Moona',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        lastLoginAt: DateTime.now(),
      );

      // Lưu trữ cục bộ trên máy
      await _saveUserLocally(userModel);

      // Đồng bộ thông tin lên Firestore document users/{uid}
      await _syncUserToFirestore(userModel);

      return userModel;
    } catch (e) {
      debugPrint('Google Sign-In Exception: $e');
      rethrow;
    }
  }

  /// Đăng nhập nhanh chế độ Trải nghiệm (Demo / Khách) khi không có Google Services
  Future<UserModel> signInAsDemo({
    String displayName = 'Người Dùng Moona',
    String email = 'user@moona.app',
    String? photoUrl,
  }) async {
    final uid = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    final userModel = UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=$displayName',
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _saveUserLocally(userModel);
    return userModel;
  }

  /// Lưu vào Hive cục bộ
  Future<void> _saveUserLocally(UserModel user) async {
    final box = _userBox;
    await box.put(AppConstants.keyUserUid, user.uid);
    await box.put(AppConstants.keyUserDisplayName, user.displayName);
    await box.put(AppConstants.keyUserEmail, user.email);
    if (user.photoUrl != null) {
      await box.put(AppConstants.keyUserPhotoUrl, user.photoUrl!);
    } else {
      await box.delete(AppConstants.keyUserPhotoUrl);
    }
    await box.put(AppConstants.keyUserIsLoggedIn, true);
  }

  /// Đồng bộ hồ sơ lên Firestore
  Future<void> _syncUserToFirestore(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync user to Firestore notice: $e');
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign out error: $e');
    }

    final box = _userBox;
    await box.put(AppConstants.keyUserIsLoggedIn, false);
    await box.delete(AppConstants.keyUserUid);
    await box.delete(AppConstants.keyUserDisplayName);
    await box.delete(AppConstants.keyUserEmail);
    await box.delete(AppConstants.keyUserPhotoUrl);
  }
}
