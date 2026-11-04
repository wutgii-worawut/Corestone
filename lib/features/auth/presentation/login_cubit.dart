import 'package:corestone/core/submit_status.dart';
import 'package:corestone/core/validators/validators.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.showErrors = false,
    this.status = const SubmitIdle(),
  });

  final String email;
  final String password;

  /// False until the first submit, so an untouched form shows no errors.
  final bool showErrors;
  final SubmitStatus status;

  FieldError? get emailError => showErrors ? validateEmail(email) : null;
  FieldError? get passwordError =>
      showErrors ? validatePassword(password) : null;

  LoginState copyWith({
    String? email,
    String? password,
    bool? showErrors,
    SubmitStatus? status,
  }) => LoginState(
    email: email ?? this.email,
    password: password ?? this.password,
    showErrors: showErrors ?? this.showErrors,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [email, password, showErrors, status];
}

/// Owns the form. A success signs in through [SessionCubit], and `App` then
/// moves to Home.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._session, {this._guard = unguarded})
    : super(const LoginState());

  final SessionCubit _session;
  final Guard _guard;

  void emailChanged(String email) =>
      emit(state.copyWith(email: email, status: _statusAfterEdit));

  void passwordChanged(String password) =>
      emit(state.copyWith(password: password, status: _statusAfterEdit));

  /// Editing clears a shown failure, so a stale error never sits under new
  /// input, but never ends a submit in flight.
  SubmitStatus get _statusAfterEdit =>
      state.status is Submitting ? state.status : const SubmitIdle();

  Future<void> submit() async {
    if (state.status is Submitting) return;
    final email = state.email.trim();
    if (validateEmail(email) != null ||
        validatePassword(state.password) != null) {
      return emit(state.copyWith(showErrors: true));
    }
    emit(state.copyWith(showErrors: true, status: const Submitting()));
    final result = await _guard(
      () => _session.signIn(email: email, password: state.password),
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        status: result.fold(SubmitFailed.new, (_) => const SubmitSucceeded()),
      ),
    );
  }
}
