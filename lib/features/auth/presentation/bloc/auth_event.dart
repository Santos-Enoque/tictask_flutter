part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class SignInWithEmailAndPassword extends AuthEvent {
  const SignInWithEmailAndPassword(
      {required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class CreateUserWithEmailAndPassword extends AuthEvent {
  const CreateUserWithEmailAndPassword(
      {required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignOut extends AuthEvent {}

class SignInWithMagicLink extends AuthEvent {
  const SignInWithMagicLink({required this.email, this.redirectTo});
  final String email;
  final String? redirectTo;

  @override
  List<Object?> get props => [email, redirectTo];
}

class SignInAnonymously extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
