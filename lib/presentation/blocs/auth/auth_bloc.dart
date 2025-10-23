import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/services/auth_storage_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String username;
  final String role;
  final String token;

  const AuthAuthenticated({
    required this.username,
    required this.role,
    required this.token,
  });

  @override
  List<Object> get props => [username, role, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthStorageService _authStorageService;

  AuthBloc(this._authStorageService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Check if user is logged in and token is valid
      final isLoggedIn = await _authStorageService.isLoggedIn();
      final isTokenValid = await _authStorageService.isTokenValid();
      
      if (isLoggedIn && isTokenValid) {
        // Get stored login info
        final loginInfo = await _authStorageService.getLoginInfo();
        final username = loginInfo['username'];
        final role = loginInfo['role'];
        final token = loginInfo['token'];
        
        if (username != null && role != null && token != null) {
          emit(AuthAuthenticated(
            username: username,
            role: role,
            token: token,
          ));
          return;
        }
      }
      
      // If no valid stored credentials, emit unauthenticated
      emit(AuthUnauthenticated());
    } catch (e) {
      // If error checking stored credentials, emit unauthenticated
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock authentication logic (matching React app credentials)
      if ((event.username == 'bashar' && event.password == 'bashar') ||
          (event.username == 'ahmed' && event.password == 'ahmed') ||
          (event.username == 'hussien' && event.password == 'hussien')) {
        
        String role = 'Operator';
        if (event.username == 'ahmed') role = 'Admin';
        if (event.username == 'hussien') role = 'Technician';
        
        // Generate mock token
        final token = _authStorageService.generateMockToken(event.username);
        
        // Save login information to SharedPreferences
        await _authStorageService.saveLoginInfo(
          token: token,
          username: event.username,
          role: role,
        );
        
        emit(AuthAuthenticated(
          username: event.username,
          role: role,
          token: token,
        ));
      } else {
        emit(const AuthError('Invalid credentials'));
      }
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Clear stored login information
      await _authStorageService.clearLoginInfo();
      
      // Simulate logout process
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if clearing fails, still logout
      emit(AuthUnauthenticated());
    }
  }
}
