import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/submit_status.dart';
import 'package:corestone/features/feedback/data/feedback_repository.dart';
import 'package:corestone/features/feedback/feedback_cubit.dart';
import 'package:corestone/features/feedback/feedback_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFeedbackRepository repository;
  late FeedbackCubit cubit;
  late List<SubmitStatus> statuses;

  setUp(() {
    repository = FakeFeedbackRepository();
    cubit = FeedbackCubit(repository);
    statuses = [];
    cubit.stream.listen((state) => statuses.add(state.status));
  });

  tearDown(() => cubit.close());

  Future<void> fillAndSubmit() async {
    cubit
      ..ratingChanged(4)
      ..messageChanged('  Love the PIN lock  ');
    await cubit.submit(locale: 'en');
  }

  test('an untouched form shows no errors', () {
    expect(cubit.state.ratingError, isNull);
    expect(cubit.state.messageError, isNull);
  });

  test('a filled form sends the trimmed draft', () async {
    await fillAndSubmit();
    await pumpEventQueue();
    expect(statuses, contains(isA<Submitting>()));
    expect(cubit.state.status, isA<SubmitSucceeded>());
    expect(repository.sent.single.rating, 4);
    expect(repository.sent.single.message, 'Love the PIN lock');
  });

  test('a sent form ignores another submit', () async {
    await fillAndSubmit();
    await cubit.submit(locale: 'en');
    expect(repository.sent, hasLength(1));
  });

  test('an empty form shows both errors and sends nothing', () async {
    await cubit.submit(locale: 'en');
    expect(cubit.state.ratingError, DraftError.noRating);
    expect(cubit.state.messageError, DraftError.noMessage);
    expect(cubit.state.status, isA<SubmitIdle>());
    expect(repository.sent, isEmpty);
  });

  test('a rating without a message shows only the message error', () async {
    cubit.ratingChanged(5);
    await cubit.submit(locale: 'en');
    expect(cubit.state.ratingError, isNull);
    expect(cubit.state.messageError, DraftError.noMessage);
    expect(repository.sent, isEmpty);
  });

  for (final (name, failure) in [
    ('offline', const NetworkFailure()),
    ('server error', const ServerFailure(500)),
  ]) {
    test('$name fails and keeps the rating and the message', () async {
      repository.failure = failure;
      await fillAndSubmit();
      expect(cubit.state.status, SubmitFailed(failure));
      expect(cubit.state.rating, 4);
      expect(cubit.state.message, '  Love the PIN lock  ');
    });
  }

  test('editing after a failure clears it, and a retry sends', () async {
    repository.failure = const NetworkFailure();
    await fillAndSubmit();
    cubit.messageChanged('Love the PIN lock!');
    expect(cubit.state.status, isA<SubmitIdle>());

    repository.failure = null;
    await cubit.submit(locale: 'en');
    expect(cubit.state.status, isA<SubmitSucceeded>());
    expect(repository.sent.single.message, 'Love the PIN lock!');
  });
}
