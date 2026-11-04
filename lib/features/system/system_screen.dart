import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/widgets/app_button.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Pops `true` on Retry. Back pops `null`, and the caller shows the failure
/// inline.
@RoutePage()
class SystemScreen extends StatelessWidget {
  const SystemScreen({required this.page, super.key});

  final SystemPage page;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, body) = switch (page) {
      SystemPage.maintenance => (
        Icons.construction,
        l10n.maintenanceTitle,
        l10n.maintenanceBody,
      ),
      SystemPage.secureConnection => (
        Icons.gpp_bad_outlined,
        l10n.secureConnectionTitle,
        l10n.secureConnectionBody,
      ),
    };
    return Scaffold(
      appBar: AppBar(),
      body: SystemMessageView(
        icon: icon,
        title: title,
        body: body,
        actionLabel: l10n.retry,
        onAction: () => unawaited(context.router.maybePop(true)),
      ),
    );
  }
}

/// The layout every system page shares, so restyling it restyles them all.
class SystemMessageView extends StatelessWidget {
  const SystemMessageView({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Icon(icon, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(label: actionLabel, onPressed: onAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
