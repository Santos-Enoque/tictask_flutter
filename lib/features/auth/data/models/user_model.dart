// lib/features/auth/data/models/user_model.dart
import 'package:supabase/supabase.dart' as supabase;
import 'package:tictask/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    super.displayName,
    super.isAnonymous = false,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
    );
  }
  
  factory UserModel.fromSupabase(supabase.User supabaseUser) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email,
      displayName: supabaseUser.userMetadata?['name'] as String?,
      isAnonymous: supabaseUser.email == 'anonymous@tictask.app',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
    };
  }
}
