import 'package:corestone/core/submit_status.dart';
import 'package:corestone/features/feedback/data/feedback_repository.dart';
import 'package:corestone/features/feedback/feedback_draft.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class FeedbackState extends Equatable {
  const FeedbackState({
    this.rating = 0,
    this.message = '',
    this.showErrors = false,
    this.status = const SubmitIdle(),
  });

  /// 0 until the user picks a star.
  final int rating;
  final String message;

  /// False until the first submit, so an untouched form shows no errors.
  final bool showErrors;
  final SubmitStatus status;

  DraftError? get ratingError =>
      showErrors ? FeedbackDraft.ratingError(rating) : null;
  DraftError? get messageError =>
      showErrors ? FeedbackDraft.messageError(message) : null;

  FeedbackState copyWith({
    int? rating,
    String? message,
    bool? showErrors,
    SubmitStatus? status,
  }) => FeedbackState(
    rating: rating ?? this.rating,
    message: message ?? this.message,
    showErrors: showErrors ?? this.showErrors,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [rating, message, showErrors, status];
}

/// Owns the feedback form. A failure keeps the rating and the message.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit(this._repository, {this._guard = unguarded})
    : super(const FeedbackState());

  final FeedbackRepository _repository;
  final Guard _guard;

  void ratingChanged(int rating) =>
      emit(state.copyWith(rating: rating, status: _statusAfterEdit));

  void messageChanged(String message) =>
      emit(state.copyWith(message: message, status: _statusAfterEdit));

  /// Editing clears a shown failure, but never ends a send in flight.
  SubmitStatus get _statusAfterEdit =>
      state.status is Submitting ? state.status : const SubmitIdle();

  Future<void> submit({required String locale}) async {
    if (state.status is Submitting || state.status is SubmitSucceeded) return;
    final draft = FeedbackDraft.tryParse(
      rating: state.rating,
      message: state.message,
    );
    if (draft == null) return emit(state.copyWith(showErrors: true));
    emit(state.copyWith(showErrors: true, status: const Submitting()));
    final result = await _guard(() => _repository.send(draft, locale: locale));
    if (isClosed) return;
    emit(
      state.copyWith(
        status: result.fold(SubmitFailed.new, (_) => const SubmitSucceeded()),
      ),
    );
  }
}
