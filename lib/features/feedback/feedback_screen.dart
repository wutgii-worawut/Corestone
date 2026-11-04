import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/errors/failure_message.dart';
import 'package:corestone/core/submit_status.dart';
import 'package:corestone/core/theme/app_colors.dart';
import 'package:corestone/core/widgets/app_button.dart';
import 'package:corestone/features/feedback/feedback_cubit.dart';
import 'package:corestone/features/feedback/feedback_draft.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FeedbackCubit(sl(), guard: sl<SystemPages>().guard),
      child: const FeedbackView(),
    );
  }
}

/// The screen without its [FeedbackCubit], so goldens can supply one.
class FeedbackView extends StatelessWidget {
  const FeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sent = context.select<FeedbackCubit, bool>(
      (cubit) => cubit.state.status is SubmitSucceeded,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendFeedback)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: sent ? const _ThankYou() : const _Form(),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<FeedbackCubit>();
    final state = context.watch<FeedbackCubit>().state;
    final sending = state.status is Submitting;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.feedbackIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text(l10n.feedbackRatingLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _StarRow(
          rating: state.rating,
          onChanged: sending ? null : cubit.ratingChanged,
        ),
        if (_draftError(l10n, state.ratingError) case final text?)
          _ErrorText(text),
        const SizedBox(height: 24),
        TextField(
          readOnly: sending,
          minLines: 4,
          maxLines: 8,
          maxLength: FeedbackDraft.maxLength,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: cubit.messageChanged,
          decoration: InputDecoration(
            labelText: l10n.feedbackMessageLabel,
            hintText: l10n.feedbackMessageHint,
            alignLabelWithHint: true,
            errorText: _draftError(l10n, state.messageError),
            border: const OutlineInputBorder(),
          ),
        ),
        if (state.status case SubmitFailed(:final failure))
          _ErrorText(failureMessage(l10n, failure)),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.feedbackSubmit,
          isLoading: sending,
          onPressed: () => cubit.submit(
            locale: Localizations.localeOf(context).toLanguageTag(),
          ),
        ),
      ],
    );
  }
}

/// Five tappable stars. Tapping star n rates n.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.appColors.warning;
    return Row(
      children: [
        for (var star = 1; star <= FeedbackDraft.maxRating; star++)
          Semantics(
            selected: star == rating,
            child: IconButton(
              iconSize: 36,
              tooltip: l10n.feedbackStars(star, FeedbackDraft.maxRating),
              onPressed: switch (onChanged) {
                null => null,
                final onChanged => () => onChanged(star),
              },
              icon: Icon(
                star <= rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

class _ThankYou extends StatelessWidget {
  const _ThankYou();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: context.appColors.success,
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.feedbackThanksTitle,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.feedbackThanksBody,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: l10n.feedbackBackToSettings,
          onPressed: () => context.router.maybePop(),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

String? _draftError(AppLocalizations l10n, DraftError? error) =>
    switch (error) {
      null => null,
      DraftError.noRating => l10n.feedbackRatingRequired,
      DraftError.noMessage => l10n.fieldRequired,
      DraftError.messageTooLong => l10n.feedbackMessageTooLong(
        FeedbackDraft.maxLength,
      ),
    };
