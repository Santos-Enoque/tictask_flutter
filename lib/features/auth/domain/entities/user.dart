// lib/features/auth/domain/entities/user.dart
class User {
  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  
  const User({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}
