// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:tictask/core/services/sync_service.dart';
import 'package:tictask/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tictask/features/auth/domain/entities/user.dart';
import 'package:tictask/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.syncService,
  });
  final AuthRemoteDataSource remoteDataSource;
  final SyncService syncService;
  
  @override
  Future<User?> getCurrentUser() async {
    return remoteDataSource.getCurrentUser();
  }
  
  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = await remoteDataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Start data sync after successful sign-in
    await syncService.syncAll();
    
    return user;
  }
  
  @override
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = await remoteDataSource.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Sync data after account creation
    await syncService.syncAll();
    
    return user;
  }
  
  @override
  Future<void> signOut() async {
    // Try to sync one last time before signing out
    await syncService.syncAll();
    
    // Then sign out
    await remoteDataSource.signOut();
  }
  
  @override
  Future<User> signInWithMagicLink({
    required String email,
    String? redirectTo,
  }) async {
    return remoteDataSource.signInWithMagicLink(
      email: email,
      redirectTo: redirectTo,
    );
  }
  
  @override
  Future<User> signInAnonymously() async {
    final user = await remoteDataSource.signInAnonymously();
    
    // Sync data after anonymous sign-in
    await syncService.syncAll();
    
    return user;
  }
  
  @override
  Stream<User?> get authStateChanges => remoteDataSource.authStateChanges;
  
  @override
  bool get isAuthenticated => remoteDataSource.isAuthenticated;
}
