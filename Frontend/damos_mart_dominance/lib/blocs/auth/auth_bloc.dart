import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SsoLoginSubmitted>(_onSsoLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<UserUpdated>(_onUserUpdated);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await SecureStorage.instance.getAccessToken();
      final userData = await SecureStorage.instance.getUserData();

      if (token != null && token.isNotEmpty && userData != null) {
        emit(Authenticated(UserModel.fromJson(userData)));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await SecureStorage.instance.saveAccessToken(event.accessToken);
      await SecureStorage.instance.saveRefreshToken(event.refreshToken);
      await SecureStorage.instance.saveUserData(event.userData);
      emit(Authenticated(UserModel.fromJson(event.userData)));
    } catch (e) {
      emit(const AuthFailure('Gagal menyimpan sesi login 😅'));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _repository.logout(refreshToken);
      }
    } catch (_) {
      // Ignore API logout error and proceed with clearing local storage
    } finally {
      await SecureStorage.instance.clearAll();
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.login(event.email, event.password);
      final user = result['user'] as UserModel;
      
      await SecureStorage.instance.saveAccessToken(result['accessToken']);
      await SecureStorage.instance.saveRefreshToken(result['refreshToken']);
      await SecureStorage.instance.saveUserData(user.toJson());
      
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSsoLoginSubmitted(SsoLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.loginSso(event.ssoToken);
      final user = result['user'] as UserModel;
      
      await SecureStorage.instance.saveAccessToken(result['accessToken']);
      await SecureStorage.instance.saveRefreshToken(result['refreshToken']);
      await SecureStorage.instance.saveUserData(user.toJson());
      
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );

      // Do NOT auto-login. Make sure no stale session is kept so the router
      // allows navigating to the login page.
      await SecureStorage.instance.clearAll();

      emit(RegistrationSuccess(event.email));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onUserUpdated(UserUpdated event, Emitter<AuthState> emit) async {
    try {
      await SecureStorage.instance.saveUserData(event.user.toJson());
    } catch (_) {}
    emit(Authenticated(event.user));
  }
}

