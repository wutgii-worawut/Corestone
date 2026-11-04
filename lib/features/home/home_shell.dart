import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/layout/adaptive_scaffold.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [HomeRoute(), SettingsRoute()],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return AdaptiveScaffold(
          selectedIndex: tabsRouter.activeIndex,
          onSelect: tabsRouter.setActiveIndex,
          destinations: [
            (icon: const Icon(Icons.home), label: context.l10n.home),
            (icon: const Icon(Icons.settings), label: context.l10n.settings),
          ],
          body: child,
        );
      },
    );
  }
}
