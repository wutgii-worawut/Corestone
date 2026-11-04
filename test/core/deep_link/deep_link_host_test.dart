import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The host lives in three files per flavor: Dart checks links against
/// config/, Android filters on Gradle's placeholder, iOS on the xcconfig.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final gradleHost = RegExp(r'manifestPlaceholders\["deepLinkHost"\] = "(.*)"');
  final xcHost = RegExp(r'^DEEP_LINK_HOST = (\S+)\s*$', multiLine: true);

  for (final flavor in ['dev', 'stage', 'prod']) {
    test('$flavor uses one deep link host everywhere', () {
      final config = jsonDecode(
        File('config/$flavor.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final host = config['DEEP_LINK_HOST'];
      expect(host, isA<String>());

      final block = RegExp('create\\("$flavor"\\) \\{[^}]*\\}')
          .stringMatch(gradle)!;
      expect(gradleHost.firstMatch(block)?.group(1), host);

      for (final build in ['Debug', 'Profile', 'Release']) {
        final xcconfig = File('ios/Flutter/$build-$flavor.xcconfig');
        expect(
          xcHost.firstMatch(xcconfig.readAsStringSync())?.group(1),
          host,
          reason: xcconfig.path,
        );
      }
    });
  }
}
