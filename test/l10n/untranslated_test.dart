import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every ARB key is translated in every locale', () {
    // gen-l10n writes this file on `flutter pub get`, per l10n.yaml.
    final file = File('build/l10n_untranslated.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'run `flutter gen-l10n` to write ${file.path}',
    );

    final untranslated = jsonDecode(file.readAsStringSync()) as Map;

    expect(untranslated, isEmpty, reason: 'untranslated keys: $untranslated');
  });
}
