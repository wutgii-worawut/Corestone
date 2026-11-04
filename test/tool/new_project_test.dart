import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/new_project.dart';

void main() {
  ProjectIdentity acme() => ProjectIdentity.parse(
    packageName: 'acme_app',
    org: 'com.acme',
    displayName: 'Acme',
  );

  test('derives every platform id from one identity', () {
    final id = acme();
    expect(id.applicationId, 'com.acme.acme_app');
    expect(id.iosBundleId, 'com.acme.acmeApp');
    expect(id.hostLabel, 'acme-app');
    expect(id.kotlinPath, 'com/acme/acme_app');
  });

  test('rejects identities the platforms or the template cannot carry', () {
    const bad = [
      ('Acme', 'com.acme', 'Acme'),
      ('1app', 'com.acme', 'Acme'),
      ('acme-app', 'com.acme', 'Acme'),
      ('acme__app', 'com.acme', 'Acme'),
      ('acme_', 'com.acme', 'Acme'),
      ('class', 'com.acme', 'Acme'),
      ('flutter', 'com.acme', 'Acme'),
      ('acme', 'acme', 'Acme'),
      ('acme', 'com.Acme', 'Acme'),
      ('acme', 'com.acme_co', 'Acme'),
      ('acme', 'com.new', 'Acme'),
      ('acme', 'com..acme', 'Acme'),
      ('acme', 'com.acme', ''),
      ('acme', 'com.acme', ' Acme'),
      ('acme', 'com.acme', 'Acme '),
      ('acme', 'com.acme', "Bob's"),
      ('acme', 'com.acme', r'A$b'),
      ('acme', 'com.acme', 'A "b"'),
      ('my_corestone', 'com.acme', 'Acme'),
      ('acme', 'com.wutstack', 'Acme'),
      ('acme', 'com.acme', 'Corestone Two'),
    ];
    for (final (name, org, display) in bad) {
      expect(
        () => ProjectIdentity.parse(
          packageName: name,
          org: org,
          displayName: display,
        ),
        throwsFormatException,
        reason: '$name $org "$display"',
      );
    }
  });

  final isTemplate =
      File('pubspec.yaml').readAsLinesSync().first == 'name: corestone';

  group(
    'renaming a copy of this repo',
    skip: isTemplate ? null : 'the template is already renamed',
    () {
      late Directory dir;

      String git(List<String> args) {
        final result = Process.runSync('git', [
          '-c',
          'user.name=t',
          '-c',
          'user.email=t@t',
          ...args,
        ], workingDirectory: dir.path);
        return (result.stdout as String).trim();
      }

      setUpAll(() {
        dir = Directory.systemTemp.createTempSync('new_project_test');
        final tracked =
            Process.runSync('git', [
                  'ls-files',
                  '--cached',
                  '--others',
                  '--exclude-standard',
                ]).stdout
                as String;
        for (final path in tracked.split('\n').where((p) => p.isNotEmpty)) {
          final source = File(path);
          if (!source.existsSync()) continue;
          final dest = File('${dir.path}/$path')
            ..parent.createSync(recursive: true);
          source.copySync(dest.path);
        }
        git(['init', '-q']);
        git(['add', '-A']);
        git(['commit', '-q', '-m', 'template']);
      });

      tearDownAll(() => dir.deleteSync(recursive: true));

      test('leaves no template identity outside the kept files', () {
        expect(generate(dir.path, acme()), isNotEmpty);
        git(['add', '-A']);
        final leftovers = git([
          'grep', '-l', '-i', '-e', 'corestone', '-e', 'wutstack', //
        ]).split('\n').where((p) => p.isNotEmpty).toSet();
        expect(leftovers.difference(keptFiles), isEmpty);
        expect(
          File(
            '${dir.path}/android/app/src/main/kotlin/com/acme/acme_app/'
            'MainActivity.kt',
          ).readAsStringSync(),
          startsWith('package com.acme.acme_app'),
        );
        expect(
          Directory('${dir.path}/android/app/src/main/kotlin/com/wutstack')
              .existsSync(),
          isFalse,
        );
        expect(
          File('${dir.path}/ios/Flutter/Debug-dev.xcconfig').readAsStringSync(),
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.acmeApp.dev'),
        );
      });

      test('refuses a dirty tree', () {
        expect(() => generate(dir.path, acme()), throwsStateError);
      });

      test('a second run with the same identity changes nothing', () {
        git(['commit', '-q', '-m', 'renamed']);
        expect(generate(dir.path, acme()), isEmpty);
        expect(git(['status', '--porcelain']), isEmpty);
      });
    },
  );
}
