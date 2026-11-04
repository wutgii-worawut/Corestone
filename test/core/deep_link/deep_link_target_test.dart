import 'package:corestone/core/deep_link/deep_link_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const host = 'dev.links.example.com';
  DeepLinkTarget? parse(String link) =>
      DeepLinkTarget.parse(Uri.parse(link), host: host);

  test('parses every known path', () {
    expect(parse('https://$host'), isA<HomeLink>());
    expect(parse('https://$host/'), isA<HomeLink>());
    expect(parse('https://$host/home'), isA<HomeLink>());
    expect(parse('https://$host/settings'), isA<SettingsLink>());
    expect(parse('https://$host/settings/theme'), isA<ThemeLink>());
    expect(parse('https://$host/settings/language'), isA<LanguageLink>());
  });

  test('ignores query, fragment, trailing slash and host case', () {
    expect(parse('https://$host/settings/?utm=mail#top'), isA<SettingsLink>());
    expect(
      parse('https://DEV.links.example.com/settings'),
      isA<SettingsLink>(),
    );
  });

  test('an unknown path of ours is UnknownLink', () {
    expect(parse('https://$host/orders/42'), isA<UnknownLink>());
    expect(parse('https://$host/Settings'), isA<UnknownLink>());
    expect(parse('https://$host/settings/pin'), isA<UnknownLink>());
    expect(parse('https://$host/settings/delete-account'), isA<UnknownLink>());
    expect(parse('https://$host/%zz%%'), isA<UnknownLink>());
  });

  test('rejects other hosts, schemes and an empty host', () {
    expect(parse('https://stage.links.example.com/settings'), isNull);
    expect(parse('https://evil.example.com/settings'), isNull);
    expect(parse('https://$host.evil.com/settings'), isNull);
    expect(parse('http://$host/settings'), isNull);
    expect(parse('corestone://settings'), isNull);
    expect(parse('/settings'), isNull);
    expect(parse('garbage'), isNull);
    expect(
      DeepLinkTarget.parse(Uri.parse('https://$host/settings'), host: ''),
      isNull,
    );
  });
}
