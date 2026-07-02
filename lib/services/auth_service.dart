import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan stream user yang sedang login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper untuk translate error Firebase ke Bahasa Indonesia
  String _translateFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau Password salah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      default:
        return e.message ?? 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _translateFirebaseError(e);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // Register
  Future<String?> register(String nama, String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      try {
        // Simpan data tambahan ke Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'nama': nama,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        // Jika gagal nyimpen ke database (misal belum dibuat di console), HAPUS akun dari Auth
        await cred.user!.delete();
        return 'Gagal menyimpan data. Pastikan Firestore Database sudah aktif di Firebase Console! ($firestoreError)';
      }
      
      // Karena FirebaseAuth otomatis nge-login pas register, kita logout paksa aja biar flow-nya rapi
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _translateFirebaseError(e);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mendapatkan role user
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
      debugPrint('Dokumen user tidak ditemukan di Firestore untuk uid: $uid');
      return null;
    } catch (e) {
      debugPrint('Error fetching role dari Firestore: $e');
      return null;
    }
  }
}
