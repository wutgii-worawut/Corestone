import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the device has a network interface up. It says nothing about
/// whether the API is reachable: a captive portal or a dead Wi-Fi still
/// reads as online.
sealed class ConnectivityState {
  const ConnectivityState();
}

final class Online extends ConnectivityState {
  const Online();
}

final class Offline extends ConnectivityState {
  const Offline();
}

/// The current state first, then every change.
Stream<List<ConnectivityResult>> connectivityChanges(Connectivity c) async* {
  yield await c.checkConnectivity();
  yield* c.onConnectivityChanged;
}

/// Starts [Online], so the app never claims offline before it knows.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(Stream<List<ConnectivityResult>> changes)
    : super(const Online()) {
    _subscription = changes.listen(
      (results) => emit(
        results.every((r) => r == ConnectivityResult.none)
            ? const Offline()
            : const Online(),
      ),
      // A platform that cannot report it keeps the last known state.
      onError: (Object _) {},
    );
  }

  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
