import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eshop_plus/ui/auth/repositories/authRepository.dart';

abstract class VerifyCredentialsState {}

class VerifyCredentialsInitial extends VerifyCredentialsState {}

class VerifyCredentialsInProgress extends VerifyCredentialsState {}

class VerifyCredentialsSuccess extends VerifyCredentialsState {
  final bool hasError;
  final String message;

  VerifyCredentialsSuccess({
    required this.hasError,
    required this.message,
  });
}

class VerifyCredentialsFailure extends VerifyCredentialsState {
  final String errorMessage;

  VerifyCredentialsFailure(this.errorMessage);
}

class VerifyCredentialsCubit extends Cubit<VerifyCredentialsState> {
  final AuthRepository _authRepository = AuthRepository();

  VerifyCredentialsCubit() : super(VerifyCredentialsInitial());

  void verifyCredentials({required Map<String, dynamic> params}) async {
    try {
      emit(VerifyCredentialsInProgress());
      final result = await _authRepository.verifyCredentials(params: params);
      emit(VerifyCredentialsSuccess(
        hasError: result.hasError,
        message: result.message,
      ));
    } catch (e) {
      emit(VerifyCredentialsFailure(e.toString()));
    }
  }
}