// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmailAndPassword(
      {required String email, required String password});
  Future<UserModel> createUserWithEmailAndPassword(
      {required String email, required String password});
  Future<void> signOut();
  Future<UserModel> signInWithMagicLink(
      {required String email, String? redirectTo});
  Future<UserModel> signInAnonymously();
  Stream<UserModel?> get authStateChanges;
  bool get isAuthenticated;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl({required this.supabase});

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabase(user);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Failed to sign in: No user returned');
    }
    return UserModel.fromSupabase(response.user!);
  }

  @override
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Failed to create user: No user returned');
    }
    return UserModel.fromSupabase(response.user!);
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Future<UserModel> signInWithMagicLink({
    required String email,
    String? redirectTo,
  }) async {
    await supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo,
    );
    // Here we would typically need to wait for the user to click the link
    // Just return a placeholder until the auth state changes
    return UserModel(
      id: 'pending_magic_link',
      email: email,
      isAnonymous: false,
    );
  }

  @override
  Future<UserModel> signInAnonymously() async {
    final response = await supabase.auth.signInWithPassword(
      email: 'anonymous@tictask.app',
      password: 'anonymous',
    );
    if (response.user == null) {
      throw Exception('Failed to sign in anonymously: No user returned');
    }
    return UserModel.fromSupabase(response.user!);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabase.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabase(user);
    });
  }

  @override
  bool get isAuthenticated => supabase.auth.currentUser != null;
}
