import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/router/app_router.gr.dart';

/// Where a deep link may open the app. Add a target here, and a path in
/// [DeepLinkTarget.parse], to make a new screen linkable. Screens that
/// change the PIN or delete the account stay unlinkable on purpose.
sealed class DeepLinkTarget {
  const DeepLinkTarget();

  /// Null when [uri] is not one of ours: not https, or not on [host]. A
  /// link of ours with a path the app does not know is [UnknownLink], so a
  /// stale or mistyped link still opens the app. Query and fragment are
  /// ignored, and so are empty segments, so `/settings/` is `/settings`.
  static DeepLinkTarget? parse(Uri uri, {required String host}) {
    if (host.isEmpty || uri.scheme != 'https' || uri.host != host) {
      return null;
    }
    final path = uri.pathSegments.where((s) => s.isNotEmpty).join('/');
    return switch (path) {
      '' || 'home' => const HomeLink(),
      'settings' => const SettingsLink(),
      'settings/theme' => const ThemeLink(),
      'settings/language' => const LanguageLink(),
      _ => const UnknownLink(),
    };
  }

  /// Replaces the stack with the target's tab, then pushes its screen over
  /// it. Two steps, because `replaceAll` only moves the tabs of its last
  /// route.
  Future<void> openIn(StackRouter router) async {
    final (tab, screen) = switch (this) {
      HomeLink() || UnknownLink() => (const HomeRoute(), null),
      SettingsLink() => (const SettingsRoute(), null),
      ThemeLink() => (const SettingsRoute(), const ChangeThemeRoute()),
      LanguageLink() => (const SettingsRoute(), const ChangeLanguageRoute()),
    };
    await router.replaceAll([
      HomeShellRoute(children: [tab]),
    ]);
    if (screen != null) await router.push(screen);
  }
}

final class HomeLink extends DeepLinkTarget {
  const HomeLink();
}

final class SettingsLink extends DeepLinkTarget {
  const SettingsLink();
}

final class ThemeLink extends DeepLinkTarget {
  const ThemeLink();
}

final class LanguageLink extends DeepLinkTarget {
  const LanguageLink();
}

/// Ours, but no screen matches. Opens Home.
final class UnknownLink extends DeepLinkTarget {
  const UnknownLink();
}
