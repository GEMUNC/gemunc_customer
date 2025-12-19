import 'package:eshop_plus/commons/models/userDetails.dart';
import 'package:eshop_plus/ui/auth/repositories/authRepository.dart';
import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';
import 'package:eshop_plus/ui/profile/address/blocs/getAddressCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Supported authentication providers
enum AuthProvider { gmail, phone }

/// Base class for all authentication states
abstract class AuthState {}

/// Initial state when the authentication status is unknown
class AuthInitial extends AuthState {}

/// State representing an unauthenticated user
class Unauthenticated extends AuthState {}

/// State representing an authenticated user with their details and token
class Authenticated extends AuthState {
  final UserDetails userDetails;
  final String token;

  Authenticated({required this.userDetails, required this.token});
}

/// Cubit managing authentication state and operations
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial()) {
    checkIsAuthenticated();
  }

  /// Checks if user is authenticated and emits appropriate state
  Future<void> checkIsAuthenticated() async {
    if (AuthRepository.getIsLogIn()) {
      emit(
        Authenticated(
          userDetails: AuthRepository.getUserDetails(),
          token: AuthRepository.getToken(),
        ),
      );
    } else {
      emit(Unauthenticated());
    }
  }

  /// Authenticates user with provided details and token
  Future<void> authenticateUser({
    required UserDetails userDetails,
    required String token,
  }) async {
    await authRepository.setToken(token);
    await authRepository.setUserDetails(userDetails);
    await authRepository.setIsLogIn(true);
    emit(Authenticated(userDetails: userDetails, token: token));
  }

  /// Clears authentication state
  void unAuthenticateUser() => emit(Unauthenticated());

  /// Signs out the current user
  Future<void> signOut(BuildContext context) async {
    if (state is! Authenticated) return;

    final userType = (state as Authenticated).userDetails.type;
    if (userType == null) return;

    await authRepository.signOutUser(context, userType);
    
    // Reset address-related cubits to clear previous user's data
    try {
      context.read<DeliveryLocationCubit>().resetToInitialState();
      context.read<GetAddressCubit>().resetToInitialState();
    } catch (e) {
      // Ignore if cubits are not available in the current context
    }
    
    emit(Unauthenticated());
  }

  /// Returns current user details or empty user if not authenticated
  UserDetails getUserDetails() {
    return state is Authenticated
        ? (state as Authenticated).userDetails
        : UserDetails();
  }

  /// Resets authentication state to initial
  void resetState() => emit(AuthInitial());
}
