import 'dart:io';

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/typedef.dart';
import 'package:corestone/features/feedback/feedback_draft.dart';
import 'package:dartz/dartz.dart';

abstract interface class FeedbackRepository {
  /// [locale] is the language tag the app shows, such as `th`.
  ResultVoid send(FeedbackDraft draft, {required String locale});
}

class RestFeedbackRepository implements FeedbackRepository {
  /// [api] must carry the auth interceptor.
  const RestFeedbackRepository(this._api);

  final ApiClient _api;

  @override
  ResultVoid send(FeedbackDraft draft, {required String locale}) => _api.post(
    '/feedback',
    parse: (_) {},
    data: {
      'rating': draft.rating,
      'message': draft.message,
      'appVersion': appVersion,
      'platform': Platform.operatingSystem,
      'locale': locale,
    },
  );
}

/// Accepts every draft, for demo mode and tests.
class FakeFeedbackRepository implements FeedbackRepository {
  /// Makes every send fail with this.
  Failure? failure;

  final sent = <FeedbackDraft>[];

  @override
  ResultVoid send(FeedbackDraft draft, {required String locale}) async {
    if (failure case final failure?) return Left(failure);
    sent.add(draft);
    return const Right(null);
  }
}
