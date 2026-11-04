// Renames this template to a new app identity.
// Usage: fvm dart run tool/new_project.dart --name acme_app --org com.acme
//   --display-name "Acme"
// See TEMPLATE.md for the full flow and what the owner still does by hand.
import 'dart:io';

/// The app identity a generated project carries, parsed and validated once.
class ProjectIdentity {
  ProjectIdentity._(this.packageName, this.org, this.displayName);

  /// Throws [FormatException] naming the first rule a value breaks.
  factory ProjectIdentity.parse({
    required String packageName,
    required String org,
    required String displayName,
  }) {
    if (!_packageName.hasMatch(packageName)) {
      throw FormatException(
        '--name must be lower_snake_case: a letter, then letters, digits and '
        'single underscores, not ending in an underscore',
        packageName,
      );
    }
    _rejectReserved('--name', packageName);
    final segments = org.split('.');
    if (segments.length < 2 || !segments.every(_orgSegment.hasMatch)) {
      throw FormatException(
        '--org must be reverse-DNS with two or more segments, each a '
        'lowercase letter followed by lowercase letters or digits',
        org,
      );
    }
    for (final segment in segments) {
      _rejectReserved('--org', segment);
    }
    if (!_displayName.hasMatch(displayName)) {
      throw FormatException(
        '--display-name must start with a letter or digit and hold only '
        'letters, digits, spaces, dots and hyphens',
        displayName,
      );
    }
    for (final value in [packageName, org, displayName]) {
      final lower = value.toLowerCase();
      if (_template.any(lower.contains)) {
        throw FormatException('must not contain the template identity', value);
      }
    }
    return ProjectIdentity._(packageName, org, displayName);
  }

  final String packageName;
  final String org;
  final String displayName;

  /// Android applicationId, namespace and Kotlin package.
  String get applicationId => '$org.$packageName';

  /// iOS bundle ids allow no underscore, so the name segment is camelCase,
  /// the same form `flutter create` uses: acme_app becomes acmeApp.
  String get iosBundleId {
    final words = packageName.split('_');
    final camel =
        words.first +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
    return '$org.$camel';
  }

  /// A DNS label and URI scheme form of the name: acme_app becomes acme-app.
  String get hostLabel => packageName.replaceAll('_', '-');

  String get kotlinPath => applicationId.replaceAll('.', '/');

  static final _packageName = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
  static final _orgSegment = RegExp(r'^[a-z][a-z0-9]*$');
  static final _displayName = RegExp(
    r'^[\p{L}\p{N}][\p{L}\p{M}\p{N} .\-]*(?<! )$',
    unicode: true,
  );
  static const _template = ['corestone', 'wutstack'];

  static void _rejectReserved(String flag, String word) {
    if (_reserved.contains(word)) {
      throw FormatException('$flag uses a reserved word', word);
    }
  }

  // Dart reserved words, Java and Kotlin keywords (the name and org become a
  // Kotlin and Java package), and package names the app already depends on.
  static final _reserved = _reservedWords.split(' ').toSet();
  static const _reservedWords =
      'abstract as assert async await base boolean break byte case catch '
      'char class const continue covariant default deferred do double '
      'dynamic else enum export extends extension external factory false '
      'final finally float for fun function get goto hide if implements '
      'import in instanceof int interface is late library long mixin '
      'native new null object of on operator package part private '
      'protected public record required rethrow return sealed set short '
      'show static strictfp super switch sync synchronized this throw '
      'throws transient true try type typealias typedef typeof val var '
      'void volatile when while with yield flutter flutter_test test '
      'patrol';
}

/// Replaces [from] with [to] in every tracked file matching one of [globs].
class Rule {
  const Rule(this.globs, this.from, this.to);

  final List<String> globs;
  final String from;
  final String to;

  bool appliesTo(String path) =>
      globs.any((g) => _globRegExp(g).hasMatch(path));
}

const _oldId = 'com.wutstack.corestone';
const _oldKotlinPath = 'com/wutstack/corestone';

/// Kept as they are: attribution, the license, and the generator itself,
/// which has to name the template identity to find it.
const keptFiles = {
  'NOTICE',
  'LICENSE',
  'TEMPLATE.md',
  'tool/new_project.dart',
  'test/tool/new_project_test.dart',
};

/// The template's own build plan; a generated app does not ship it.
const templateOnlyFiles = ['spec/template-plan.md'];

const _androidText = [
  'android/**/*.kts',
  'android/**/*.kt',
  'android/**/*.java',
  'android/**/*.xml',
];
const _iosText = ['ios/**/*.xcconfig', 'ios/**/*.pbxproj', 'ios/**/*.plist'];

const _kotlinRoots = [
  'android/app/src/main/kotlin',
  'android/app/src/androidTest/java',
];

List<Rule> rulesFor(ProjectIdentity id) {
  final name = id.packageName;
  final display = id.displayName;
  return [
    Rule(['**/*.dart'], 'package:corestone/', 'package:$name/'),
    Rule(['**/*.dart'], 'corestone://', '${id.hostLabel}://'),
    Rule(['**/*.dart'], "'Corestone", "'$display"),
    Rule(['**/*.dart', 'README.md'], '@corestone', '@${id.hostLabel}'),
    Rule(['pubspec.yaml'], 'name: corestone', 'name: $name'),
    Rule(['pubspec.yaml'], 'app_name: Corestone', 'app_name: $display'),
    Rule(
      ['pubspec.yaml'],
      'package_name: $_oldId',
      'package_name: '
          '${id.applicationId}',
    ),
    Rule(
      ['pubspec.yaml'],
      'bundle_id: $_oldId',
      'bundle_id: '
          '${id.iosBundleId}',
    ),
    Rule(_androidText + ['README.md'], _oldId, id.applicationId),
    Rule(['android/app/build.gradle.kts'], '"Corestone', '"$display'),
    Rule(_iosText, _oldId, id.iosBundleId),
    Rule(
      ['ios/Flutter/*.xcconfig'],
      'APP_DISPLAY_NAME = Corestone',
      'APP_DISPLAY_NAME = $display',
    ),
    Rule(
      ['ios/Runner/Info.plist'],
      '<string>corestone</string>',
      '<string>$name</string>',
    ),
    Rule(['README.md'], 'Corestone', display),
  ];
}

/// Renames the git work tree at [root] to [id] and returns one line per
/// change. Refuses a dirty tree, so every change can be reviewed and undone
/// with git. Running it again with the same identity returns no changes.
List<String> generate(String root, ProjectIdentity id) {
  if (_git(root, ['status', '--porcelain']).isNotEmpty) {
    throw StateError('the git tree is dirty; commit or stash first');
  }
  final files = _git(root, ['ls-files']).split('\n')
    ..removeWhere((f) => f.isEmpty || keptFiles.contains(f));
  final rules = rulesFor(id);
  final changes = <String>[];

  for (final path in files) {
    final matching = rules.where((r) => r.appliesTo(path));
    final file = File('$root/$path');
    if (matching.isEmpty || !file.existsSync()) continue;
    final before = file.readAsStringSync();
    var after = before;
    for (final rule in matching) {
      after = after.replaceAll(rule.from, rule.to);
    }
    if (after != before) {
      file.writeAsStringSync(after);
      changes.add('changed $path');
    }
  }

  for (final base in _kotlinRoots) {
    final from = Directory('$root/$base/$_oldKotlinPath');
    if (!from.existsSync()) continue;
    for (final entity in from.listSync(recursive: true).whereType<File>()) {
      final rel = entity.path
          .replaceAll(r'\', '/')
          .substring(from.path.replaceAll(r'\', '/').length + 1);
      final dest = File('$root/$base/${id.kotlinPath}/$rel');
      dest.parent.createSync(recursive: true);
      entity.renameSync(dest.path);
      changes.add(
        'moved $base/$_oldKotlinPath/$rel -> '
        '$base/${id.kotlinPath}/$rel',
      );
    }
    _deleteEmptyUpTo(from, Directory('$root/$base'));
  }

  for (final path in templateOnlyFiles) {
    final file = File('$root/$path');
    if (!file.existsSync()) continue;
    file.deleteSync();
    _deleteEmptyUpTo(file.parent, Directory(root));
    changes.add('removed $path');
  }
  return changes;
}

void _deleteEmptyUpTo(Directory dir, Directory stop) {
  var current = dir;
  while (current.path != stop.path && current.existsSync()) {
    if (current.listSync(recursive: true).whereType<File>().isNotEmpty) return;
    current.deleteSync(recursive: true);
    current = current.parent;
  }
}

String _git(String root, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: root);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

RegExp _globRegExp(String glob) {
  final pattern = RegExp.escape(glob)
      .replaceAll(r'\*\*/', '(.*/)?')
      .replaceAll(r'\*\*', '.*')
      .replaceAll(r'\*', '[^/]*');
  return RegExp('^$pattern\$');
}

const _usage =
    'usage: fvm dart run tool/new_project.dart --name acme_app '
    '--org com.acme --display-name "Acme"';

void main(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    options[args[i]] = args[i + 1];
  }
  final name = options['--name'];
  final org = options['--org'];
  final display = options['--display-name'];
  if (args.length.isOdd || name == null || org == null || display == null) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  final ProjectIdentity id;
  final List<String> changes;
  try {
    id = ProjectIdentity.parse(
      packageName: name,
      org: org,
      displayName: display,
    );
    changes = generate(Directory.current.path, id);
  } on FormatException catch (e) {
    stderr.writeln('invalid identity: ${e.message} (got "${e.source}")');
    exitCode = 64;
    return;
  } on StateError catch (e) {
    stderr.writeln('refused: ${e.message}');
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'identity: ${id.packageName}, Android ${id.applicationId}, '
    'iOS ${id.iosBundleId}, name "${id.displayName}"',
  );
  if (changes.isEmpty) {
    stdout.writeln('no changes');
    return;
  }
  changes.forEach(stdout.writeln);
  stdout
    ..writeln('${changes.length} changes')
    ..writeln(
      'next: fvm flutter pub get, then '
      'fvm dart fix --apply --code=directives_ordering, then commit. '
      'See TEMPLATE.md.',
    );
}
