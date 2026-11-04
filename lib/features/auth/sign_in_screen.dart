import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Placeholder until CS-08 builds the real login screen.
@RoutePage()
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.signIn)),
      body: Center(
        child: kDebugMode
            ? FilledButton(
                onPressed: () => _signInAsDemo(context),
                child: const Text('Sign in as demo user'),
              )
            : null,
      ),
    );
  }
}

/// The mock API's demo account, see tool/mock_api/server.dart.
Future<void> _signInAsDemo(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await sl<SessionCubit>().signIn(
    email: 'demo@corestone.dev',
    password: 'demo-password',
  );
  result.fold(
    (failure) => messenger.showSnackBar(SnackBar(content: Text('$failure'))),
    (_) {},
  );
}
