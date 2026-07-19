import 'package:equatable/equatable.dart';

enum UserRole { student, admin }

enum DiscPersonalityType { dominance, influence, steadiness, conscientiousness }

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final DiscPersonalityType? discType;
  final String? ssoId;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.discType,
    this.ssoId,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Role mapping
    UserRole parsedRole = UserRole.student;
    if (json['role'] == 'ADMIN') {
      parsedRole = UserRole.admin;
    }

    // DISC type mapping
    DiscPersonalityType? parsedDisc;
    if (json['discType'] != null) {
      switch (json['discType']) {
        case 'DOMINANCE':
          parsedDisc = DiscPersonalityType.dominance;
          break;
        case 'INFLUENCE':
          parsedDisc = DiscPersonalityType.influence;
          break;
        case 'STEADINESS':
          parsedDisc = DiscPersonalityType.steadiness;
          break;
        case 'CONSCIENTIOUSNESS':
          parsedDisc = DiscPersonalityType.conscientiousness;
          break;
      }
    }

    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: parsedRole,
      discType: parsedDisc,
      ssoId: json['ssoId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    String? discStr;
    if (discType != null) {
      switch (discType!) {
        case DiscPersonalityType.dominance:
          discStr = 'DOMINANCE';
          break;
        case DiscPersonalityType.influence:
          discStr = 'INFLUENCE';
          break;
        case DiscPersonalityType.steadiness:
          discStr = 'STEADINESS';
          break;
        case DiscPersonalityType.conscientiousness:
          discStr = 'CONSCIENTIOUSNESS';
          break;
      }
    }

    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role == UserRole.admin ? 'ADMIN' : 'STUDENT',
      'discType': discStr,
      'ssoId': ssoId,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        avatarUrl,
        role,
        discType,
        ssoId,
        isActive,
      ];
}
