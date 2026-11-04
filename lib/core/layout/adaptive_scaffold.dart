import 'package:corestone/core/layout/breakpoints.dart';
import 'package:flutter/material.dart';

typedef AdaptiveDestination = ({Widget icon, String label});

/// A bottom [NavigationBar] on compact windows, a [NavigationRail] otherwise.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.body,
    super.key,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    final extended = size == WindowSize.expanded;
    return Scaffold(
      body: Row(
        children: [
          if (size != WindowSize.compact) ...[
            SafeArea(
              right: false,
              child: NavigationRail(
                extended: extended,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelect,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: d.icon,
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
          ],
          // The key keeps the body's state when the rail comes and goes.
          Expanded(key: const ValueKey('body'), child: body),
        ],
      ),
      bottomNavigationBar: size == WindowSize.compact
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: d.icon, label: d.label),
              ],
            )
          : null,
    );
  }
}
