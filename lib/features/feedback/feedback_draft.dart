import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

/// Why the feedback form cannot be sent yet.
enum DraftError { noRating, noMessage, messageTooLong }

/// Feedback that is ready to send. Only [tryParse] builds one, so a draft
/// always has a rating from 1 to 5 and a trimmed, non-empty message.
final class FeedbackDraft extends Equatable {
  const FeedbackDraft._(this.rating, this.message);

  static const maxRating = 5;

  /// Counted in characters as the user sees them, like the field's counter.
  static const maxLength = 500;

  final int rating;
  final String message;

  static DraftError? ratingError(int rating) =>
      rating < 1 || rating > maxRating ? DraftError.noRating : null;

  static DraftError? messageError(String message) {
    final text = message.trim();
    if (text.isEmpty) return DraftError.noMessage;
    if (text.characters.length > maxLength) return DraftError.messageTooLong;
    return null;
  }

  /// Null when either field has an error.
  static FeedbackDraft? tryParse({
    required int rating,
    required String message,
  }) => ratingError(rating) == null && messageError(message) == null
      ? FeedbackDraft._(rating, message.trim())
      : null;

  @override
  List<Object?> get props => [rating, message];
}
