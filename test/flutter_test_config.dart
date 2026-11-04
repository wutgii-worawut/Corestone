import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  // GitHub Actions sets CI as a process env var, not a dart-define.
  final isRunningInCi = Platform.environment['CI'] == 'true';
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isRunningInCi),
      ciGoldensConfig: CiGoldensConfig(enabled: isRunningInCi),
    ),
    run: () async => testMain(),
  );
}
