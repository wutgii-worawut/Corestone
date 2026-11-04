import 'package:corestone/features/feedback/feedback_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a rating from 1 to 5 and a message make a trimmed draft', () {
    final draft = FeedbackDraft.tryParse(rating: 4, message: '  Nice app \n');
    expect(draft?.rating, 4);
    expect(draft?.message, 'Nice app');
  });

  for (final rating in [0, 6, -1]) {
    test('rating $rating is not a rating', () {
      expect(FeedbackDraft.ratingError(rating), DraftError.noRating);
      expect(FeedbackDraft.tryParse(rating: rating, message: 'ok'), isNull);
    });
  }

  test('a blank message is missing', () {
    expect(FeedbackDraft.messageError(' \n\t'), DraftError.noMessage);
    expect(FeedbackDraft.tryParse(rating: 3, message: '   '), isNull);
  });

  test('the length limit counts characters as the user sees them', () {
    // Each Thai syllable here is two code units but one character.
    final thai = 'กิ' * FeedbackDraft.maxLength;
    expect(FeedbackDraft.messageError(thai), isNull);
    expect(FeedbackDraft.messageError('${thai}x'), DraftError.messageTooLong);
    expect(FeedbackDraft.messageError('  ${'a' * 500}  '), isNull);
  });
}
