import 'package:corestone/core/errors/failure.dart';

/// Where a one-shot action, such as a form submit, stands.
sealed class SubmitStatus {
  const SubmitStatus();
}

final class SubmitIdle extends SubmitStatus {
  const SubmitIdle();
}

final class Submitting extends SubmitStatus {
  const Submitting();
}

final class SubmitFailed extends SubmitStatus {
  const SubmitFailed(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is SubmitFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}

final class SubmitSucceeded extends SubmitStatus {
  const SubmitSucceeded();
}
