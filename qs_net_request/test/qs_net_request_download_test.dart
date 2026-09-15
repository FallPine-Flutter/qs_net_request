import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qs_net_request/qs_net_request.dart';
import 'package:qs_net_request/qs_net_request_error.dart';

void main() {
  late HttpServer server;
  late Directory temporaryDirectory;
  late Uri baseUri;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'qs_net_request_download_test_',
    );
    baseUri = Uri.parse('http://${server.address.host}:${server.port}');

    unawaited(
      server
          .forEach((HttpRequest request) async {
            if (request.uri.path == '/download') {
              final queryValue = request.uri.queryParameters['query'];
              final headerValue = request.headers.value('x-download-test');
              final body = '$queryValue:$headerValue';
              request.response
                ..statusCode = HttpStatus.ok
                ..contentLength = body.length
                ..write(body);
              await request.response.close();
              return;
            }

            if (request.uri.path == '/cancel') {
              request.response
                ..statusCode = HttpStatus.ok
                ..contentLength = 1024 * 100;
              for (var index = 0; index < 100; index++) {
                request.response.add(List<int>.filled(1024, index));
                await request.response.flush();
                await Future<void>.delayed(const Duration(milliseconds: 5));
              }
              await request.response.close();
              return;
            }

            request.response
              ..statusCode = HttpStatus.notFound
              ..write('not found');
            await request.response.close();
          })
          .catchError((Object _) {}),
    );
  });

  tearDownAll(() async {
    await server.close(force: true);
    await temporaryDirectory.delete(recursive: true);
  });

  test('downloadFile writes the file and reports progress', () async {
    final savePath = '${temporaryDirectory.path}/success.txt';
    var progressCallCount = 0;
    var receivedBytes = 0;
    var totalBytes = 0;

    final result = await QsNetRequest.getInstance().downloadFile(
      apiUrl: baseUri.resolve('/download').toString(),
      savePath: savePath,
      parameters: {'query': 'parameter'},
      headers: {'x-download-test': 'header'},
      isShowLoading: false,
      onReceiveProgress: (int received, int total) {
        progressCallCount++;
        receivedBytes = received;
        totalBytes = total;
      },
    );

    expect(result, savePath);
    expect(await File(savePath).readAsString(), 'parameter:header');
    expect(progressCallCount, greaterThan(0));
    expect(receivedBytes, totalBytes);
    expect(totalBytes, greaterThan(0));
  });

  test('downloadFile deletes the partial file after cancellation', () async {
    final savePath = '${temporaryDirectory.path}/cancel.txt';
    final cancelToken = CancelToken();
    QsNetRequestError? receivedError;

    final result = await QsNetRequest.getInstance().downloadFile(
      apiUrl: baseUri.resolve('/cancel').toString(),
      savePath: savePath,
      isShowLoading: false,
      cancelToken: cancelToken,
      onReceiveProgress: (int received, int total) {
        if (received > 0 && !cancelToken.isCancelled) {
          QsNetRequest.getInstance().cancelDownload(
            cancelToken: cancelToken,
            reason: 'cancel download test',
          );
        }
      },
      onError: (QsNetRequestError error) {
        receivedError = error;
      },
    );

    expect(result, isNull);
    expect(receivedError?.code, QsNetRequestError.dioError);
    expect(await File(savePath).exists(), isFalse);
  });

  test('cancelDownload safely ignores an already cancelled token', () {
    final cancelToken = CancelToken();
    final request = QsNetRequest.getInstance();

    request.cancelDownload(
      cancelToken: cancelToken,
      reason: 'first cancellation',
    );
    request.cancelDownload(
      cancelToken: cancelToken,
      reason: 'second cancellation',
    );

    expect(cancelToken.isCancelled, isTrue);
    expect(cancelToken.cancelError?.error, 'first cancellation');
  });

  test('downloadFile reports the HTTP status and deletes the file', () async {
    final savePath = '${temporaryDirectory.path}/not_found.txt';
    QsNetRequestError? receivedError;

    final result = await QsNetRequest.getInstance().downloadFile(
      apiUrl: baseUri.resolve('/not-found').toString(),
      savePath: savePath,
      isShowLoading: false,
      onError: (QsNetRequestError error) {
        receivedError = error;
      },
    );

    expect(result, isNull);
    expect(receivedError?.code, HttpStatus.notFound);
    expect(await File(savePath).exists(), isFalse);
  });
}
