import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Corestone ${sl<AppConfig>().flavor.name}')),
      body: const Center(child: Text('Home')),
    );
  }
}
