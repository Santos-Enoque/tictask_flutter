import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/features/auth/domain/entities/user.dart';
import 'package:tictask/features/auth/domain/repositories/auth_repository.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInWithEmailAndPassword>(_onSignInWithEmailAndPassword);
    on<CreateUserWithEmailAndPassword>(_onCreateUserWithEmailAndPassword);
    on<SignOut>(_onSignOut);
    on<SignInWithMagicLink>(_onSignInWithMagicLink);
    on<SignInAnonymously>(_onSignInAnonymously);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Subscribe to auth state changes
    _authSubscription = authRepository.authStateChanges.listen((user) {
      add(AuthStateChanged(user));
    });
  }
  final AuthRepository authRepository;
  StreamSubscription<User?>? _authSubscription;

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithEmailAndPassword(
      SignInWithEmailAndPassword event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCreateUserWithEmailAndPassword(
      CreateUserWithEmailAndPassword event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await authRepository.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithMagicLink(
      SignInWithMagicLink event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await authRepository.signInWithMagicLink(
        email: event.email,
        redirectTo: event.redirectTo,
      );
      // The auth state will be updated via the subscription
      // When the user clicks the magic link
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInAnonymously(
      SignInAnonymously event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.signInAnonymously();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthStateChanged(
      AuthStateChanged event, Emitter<AuthState> emit) async {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(const Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
