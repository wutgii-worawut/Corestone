import 'dart:convert';
import 'dart:io';

import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/error_mapper.dart';
import 'package:corestone/core/network/pinning.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

const _certPath = 'test/core/network/fixtures/test_cert.pem';
const _keyPath = 'test/core/network/fixtures/test_key.pem';

List<int> _certDer() {
  final pem = File(_certPath).readAsLinesSync();
  return base64.decode(pem.where((l) => !l.startsWith('-----')).join());
}

void main() {
  const der = [1, 2, 3, 4];
  final pin = sha256.convert(der).toString();
  final otherPin = sha256.convert([9]).toString();

  test('no pins allows any certificate', () {
    expect(certMatchesPins(der, []), isTrue);
  });

  test('a matching pin allows, including as the backup pin', () {
    expect(certMatchesPins(der, [pin]), isTrue);
    expect(certMatchesPins(der, [otherPin, pin]), isTrue);
  });

  test('a wrong pin rejects', () {
    expect(certMatchesPins(der, [otherPin]), isFalse);
  });

  group('over TLS', () {
    late SecureServerSocket server;
    var bytesReceived = 0;

    setUp(() async {
      bytesReceived = 0;
      server = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
        SecurityContext()
          ..useCertificateChain(_certPath)
          ..usePrivateKey(_keyPath),
      );
      server.listen((socket) {
        socket.listen((data) {
          bytesReceived += data.length;
          socket
            ..write('HTTP/1.1 200 OK\r\ncontent-length: 2\r\n\r\nok')
            ..close();
        }, onError: (_) {});
      }, onError: (_) {});
    });

    tearDown(() => server.close());

    Future<Object> call(List<String> pins, {String scheme = 'https'}) async {
      final dio = Dio()
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => pinnedHttpClient(
            pins,
            context: SecurityContext()..setTrustedCertificates(_certPath),
          ),
        );
      try {
        return (await dio.get<String>('$scheme://127.0.0.1:${server.port}/me'))
            .data!;
      } on DioException catch (e) {
        return mapDioError(e);
      }
    }

    test('the leaf pin lets the request through', () async {
      expect(await call([sha256.convert(_certDer()).toString()]), 'ok');
    });

    test('a wrong pin fails before any request byte is sent', () async {
      expect(await call([otherPin]), const PinningFailure());
      expect(bytesReceived, 0);
    });

    test('http is refused when pins are set', () async {
      final pin = sha256.convert(_certDer()).toString();
      expect(await call([pin], scheme: 'http'), const PinningFailure());
      expect(bytesReceived, 0);
    });
  });
}
