import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> userData;

  const LoggedIn({
    required this.accessToken,
    required this.refreshToken,
    required this.userData,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, userData];
}

class LoggedOut extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SsoLoginSubmitted extends AuthEvent {
  final String ssoToken;

  const SsoLoginSubmitted({required this.ssoToken});

  @override
  List<Object?> get props => [ssoToken];
}

class RegisterSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;

  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [fullName, email, password, phone];
}

class UserUpdated extends AuthEvent {
  final UserModel user;

  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

