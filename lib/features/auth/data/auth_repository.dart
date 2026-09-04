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

  /// Web Client ID (client_type: 3) từ Google Services Firebase Console của dự án Moona
  static const String defaultServerClientId =
      '928842055742-ama9jv6hella1oobunsfvkcbkvl58gl1.apps.googleusercontent.com';

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
    String? serverClientId,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: serverClientId ?? defaultServerClientId,
              scopes: const ['email', 'profile'],
            ),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Box get _userBox => Hive.box(AppConstants.userBoxName);
  Box get _settingsBox => Hive.box(AppConstants.settingsBoxName);

  /// Đọc vai trò người dùng đã lưu trên Firestore (nếu có)
  Future<String?> getUserRoleFromFirestore(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      debugPrint('getUserRoleFromFirestore notice: $e');
    }
    return null;
  }

  /// Cập nhật vai trò người dùng lên Firestore users/{uid}
  Future<void> syncUserRoleToFirestore(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('syncUserRoleToFirestore notice: $e');
    }
  }

  /// Lấy thông tin người dùng hiện tại (từ Hive cục bộ hoặc FirebaseAuth)
  UserModel? getCurrentUser() {
    try {
      final isLoggedIn = _userBox.get(AppConstants.keyUserIsLoggedIn, defaultValue: false) as bool;
      final savedRole = _userBox.get('user_role') as String? ?? _settingsBox.get('app_user_role') as String?;

      if (!isLoggedIn) {
        final fbUser = _firebaseAuth.currentUser;
        if (fbUser != null) {
          return UserModel(
            uid: fbUser.uid,
            displayName: fbUser.displayName ?? 'Người dùng Moona',
            email: fbUser.email ?? '',
            photoUrl: fbUser.photoURL,
            role: savedRole,
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
        role: savedRole,
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

      // 1. Kiểm tra vai trò đã lưu trước đó trên Firestore Cloud (nếu có)
      final cloudRole = await getUserRoleFromFirestore(user.uid);

      final userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? googleUser.displayName ?? 'Người dùng Moona',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        role: cloudRole,
        lastLoginAt: DateTime.now(),
      );

      // 2. Lưu trữ cục bộ trên máy
      await _saveUserLocally(userModel);

      // 3. Khôi phục vai trò từ Cloud vào Hive cục bộ (nếu có)
      if (cloudRole != null && (cloudRole == 'wife' || cloudRole == 'husband')) {
        await _settingsBox.put('app_user_role', cloudRole);
        await _settingsBox.put('partner_user_role', cloudRole);
        await _settingsBox.put(AppConstants.keyHasSelectedRole, true);
        await _settingsBox.put(AppConstants.keyIsOnboardingCompleted, true);
      } else {
        // Tài khoản mới chưa có vai trò: reset cờ để dẫn vào RoleSelectionScreen
        await _settingsBox.delete('app_user_role');
        await _settingsBox.delete('partner_user_role');
        await _settingsBox.put(AppConstants.keyHasSelectedRole, false);
      }

      // 4. Đồng bộ thông tin lên Firestore document users/{uid}
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
    final savedRole = _settingsBox.get('app_user_role') as String?;

    final userModel = UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=$displayName',
      role: savedRole,
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
    if (user.role != null) {
      await box.put('user_role', user.role!);
    } else {
      await box.delete('user_role');
    }
    await box.put(AppConstants.keyUserIsLoggedIn, true);
  }

  /// Đồng bộ hồ sơ lên Firestore
  Future<void> _syncUserToFirestore(UserModel user) async {
    try {
      final payload = <String, dynamic>{
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (user.role != null) {
        payload['role'] = user.role;
      }

      await _firestore.collection('users').doc(user.uid).set(
        payload,
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Sync user to Firestore notice: $e');
    }
  }

  /// Đăng xuất khỏi hệ thống & Xóa sạch cache người dùng và vai trò
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }

    try {
      await _googleSignIn.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        debugPrint('Google disconnect error (safe to ignore): $e');
      }
    } catch (e) {
      debugPrint('Google sign out error: $e');
    }

    // 1. Xóa sạch thông tin tài khoản đăng nhập trong userBox
    final box = _userBox;
    await box.clear();

    // 2. Xóa sạch toàn bộ cache vai trò, ghép đôi, danh xưng legacy không gắn tiền tố UID
    final settingsBox = _settingsBox;
    await settingsBox.delete('app_user_role');
    await settingsBox.delete('partner_user_role');
    await settingsBox.delete('partner_couple_id');
    await settingsBox.delete('partner_pairing_code');
    await settingsBox.delete('partner_wife_user_id');
    await settingsBox.delete('partner_offline_pairing_code');
    await settingsBox.delete('nickname_call_partner');
    await settingsBox.delete('nickname_self_call');
    await settingsBox.delete(AppConstants.keyHasSelectedRole);
    await settingsBox.delete(AppConstants.keyIsOnboardingCompleted);
    await settingsBox.delete(AppConstants.keyLastPeriodStart);
    await settingsBox.delete(AppConstants.keyCycleLength);
    await settingsBox.delete(AppConstants.keyPeriodDuration);
  }
}
