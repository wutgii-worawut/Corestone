import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/errors/failure_message.dart';
import 'package:corestone/core/submit_status.dart';
import 'package:corestone/core/widgets/app_button.dart';
import 'package:corestone/features/auth/domain/account_repository.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Deletes the account, then signs out, and `App` moves to login.
class DeleteAccountCubit extends Cubit<SubmitStatus> {
  DeleteAccountCubit(this._account, this._session, {this._guard = unguarded})
    : super(const SubmitIdle());

  final AccountRepository _account;
  final SessionCubit _session;
  final Guard _guard;

  Future<void> delete() async {
    if (state is Submitting) return;
    emit(const Submitting());
    final result = await _guard(_account.deleteAccount);
    await result.fold((failure) async => emit(SubmitFailed(failure)), (
      _,
    ) async {
      emit(const SubmitSucceeded());
      await _session.signOut();
    });
  }
}

/// This screen is the confirmation step, so its button deletes at once.
@RoutePage()
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) =>
          DeleteAccountCubit(sl(), sl(), guard: sl<SystemPages>().guard),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.deleteAccount)),
        body: BlocBuilder<DeleteAccountCubit, SubmitStatus>(
          builder: (context, status) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.deleteAccountTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.deleteAccountBody),
              if (status case SubmitFailed(:final failure)) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    failureMessage(l10n, failure),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: l10n.deleteAccountConfirm,
                isLoading: status is Submitting || status is SubmitSucceeded,
                onPressed: context.read<DeleteAccountCubit>().delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
