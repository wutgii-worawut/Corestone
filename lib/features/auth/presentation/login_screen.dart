import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/errors/failure_message.dart';
import 'package:corestone/core/submit_status.dart';
import 'package:corestone/core/validators/validators.dart';
import 'package:corestone/core/widgets/app_button.dart';
import 'package:corestone/features/auth/presentation/login_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LoginCubit(sl<SessionCubit>(), guard: sl<SystemPages>().guard),
      child: const LoginView(),
    );
  }
}

/// The form without its [LoginCubit], so goldens can supply one.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<LoginCubit>();
    final state = context.watch<LoginCubit>().state;
    final submitting = state.status is Submitting;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signIn)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.loginTitle, style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(l10n.loginSubtitle, style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  TextField(
                    readOnly: submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    onChanged: cubit.emailChanged,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      errorText: _fieldError(l10n, state.emailError),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    readOnly: submitting,
                    errorText: _fieldError(l10n, state.passwordError),
                    onChanged: cubit.passwordChanged,
                    onSubmitted: cubit.submit,
                  ),
                  if (state.status case SubmitFailed(:final failure)) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _loginError(l10n, failure),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: l10n.signIn,
                    isLoading: submitting,
                    onPressed: cubit.submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.readOnly,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final bool readOnly;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      readOnly: widget.readOnly,
      obscureText: _obscured,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.password],
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted(),
      decoration: InputDecoration(
        labelText: l10n.password,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

String? _fieldError(AppLocalizations l10n, FieldError? error) =>
    switch (error) {
      null => null,
      FieldError.required => l10n.fieldRequired,
      FieldError.invalidEmail => l10n.invalidEmail,
    };

/// On sign-in, a 401 means the credentials, not an expired session.
String _loginError(AppLocalizations l10n, Failure failure) =>
    failure is UnauthorizedFailure
    ? l10n.loginWrongCredentials
    : failureMessage(l10n, failure);
