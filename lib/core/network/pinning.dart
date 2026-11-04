import 'dart:io';

import 'package:crypto/crypto.dart';

/// Thrown when the server's leaf certificate matches no configured pin.
class PinMismatchException implements Exception {
  const PinMismatchException(this.host);

  final String host;

  @override
  String toString() => 'PinMismatchException: $host';
}

/// True when the SHA-256 of [der] equals one of [pins], or [pins] is empty.
bool certMatchesPins(List<int> der, List<String> pins) =>
    pins.isEmpty || pins.contains(sha256.convert(der).toString());

/// An [HttpClient] that checks the leaf certificate against [pins] right
/// after the TLS handshake, before any request bytes are sent.
///
/// The platform trust store still applies first, so a pin narrows trust and
/// never widens it. Proxies are bypassed, since a proxy tunnel would do its
/// own handshake outside this check. [context] replaces the platform trust
/// store, which only tests do.
HttpClient pinnedHttpClient(List<String> pins, {SecurityContext? context}) =>
    HttpClient()
      ..findProxy = ((_) => 'DIRECT')
      ..connectionFactory = (uri, proxyHost, proxyPort) async {
        if (uri.scheme != 'https') {
          return Socket.startConnect(uri.host, uri.port);
        }
        final task = await SecureSocket.startConnect(
          uri.host,
          uri.port,
          context: context,
        );
        return ConnectionTask.fromSocket(
          task.socket.then((socket) {
            final cert = socket.peerCertificate;
            if (cert == null || !certMatchesPins(cert.der, pins)) {
              socket.destroy();
              throw PinMismatchException(uri.host);
            }
            return socket;
          }),
          task.cancel,
        );
      };
