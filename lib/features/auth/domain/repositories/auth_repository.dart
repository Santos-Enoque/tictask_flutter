// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:tictask/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signInWithEmailAndPassword({required String email, required String password});
  Future<User> createUserWithEmailAndPassword({required String email, required String password});
  Future<void> signOut();
  Future<User> signInWithMagicLink({required String email, String? redirectTo});
  Future<User> signInAnonymously();
  Stream<User?> get authStateChanges;
  bool get isAuthenticated;
}
