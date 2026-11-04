import 'package:corestone/core/network/connectivity_cubit.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A strip across the top of every screen while [ConnectivityCubit] reads
/// offline. It takes the status bar inset, so app bars below it sit flush.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityCubit>().state is Offline;
    final colors = Theme.of(context).colorScheme;
    // One tree for both states, so going offline never rebuilds the app.
    return Column(
      children: [
        if (offline)
          // The banner sits under the status bar, so its icons follow it.
          AnnotatedRegion(
            value:
                ThemeData.estimateBrightnessForColor(colors.inverseSurface) ==
                    Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Material(
              color: colors.inverseSurface,
              child: SafeArea(
                bottom: false,
                child: Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 18,
                          color: colors.onInverseSurface,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.offlineBanner,
                            style: TextStyle(color: colors.onInverseSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          key: const ValueKey('app'),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: offline,
            child: child,
          ),
        ),
      ],
    );
  }
}
