import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qs_net_request/qs_net_request.dart';
import 'package:qs_net_request/qs_net_request_error.dart';

void main() {
  late HttpServer server;
  late Directory temporaryDirectory;
  late Uri baseUri;
  late File firstFile;
  late File secondFile;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'qs_net_request_upload_test_',
    );
    baseUri = Uri.parse('http://${server.address.host}:${server.port}');
    firstFile = await File(
      '${temporaryDirectory.path}/first.txt',
    ).writeAsString('first file content');
    secondFile = await File(
      '${temporaryDirectory.path}/second.txt',
    ).writeAsString('second file content');

    unawaited(
      server
          .forEach((HttpRequest request) async {
            String requestBody;
            try {
              requestBody = await utf8.decoder.bind(request).join();
            } on HttpException {
              return;
            }

            if (request.uri.path == '/upload') {
              final responseData = {
                'success': true,
                'header': request.headers.value('x-upload-test'),
                'fileFieldCount': RegExp(
                  'name="files"',
                ).allMatches(requestBody).length,
                'hasFirstFile': requestBody.contains('first file content'),
                'hasSecondFile': requestBody.contains('second file content'),
                'hasCustomFileName': requestBody.contains(
                  'filename="custom-second.txt"',
                ),
                'hasParameter': requestBody.contains('parameter value'),
              };
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.json
                ..write(jsonEncode(responseData));
              await request.response.close();
              return;
            }

            if (request.uri.path == '/empty') {
              request.response.statusCode = HttpStatus.ok;
              await request.response.close();
              return;
            }

            if (request.uri.path == '/invalid') {
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.text
                ..write('invalid response');
              await request.response.close();
              return;
            }

            if (request.uri.path == '/slow-upload') {
              await Future<void>.delayed(const Duration(seconds: 2));
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.json
                ..write('{"success":true}');
              await request.response.close();
              return;
            }

            request.response
              ..statusCode = HttpStatus.notFound
              ..headers.contentType = ContentType.json
              ..write('{"message":"not found"}');
            await request.response.close();
          })
          .catchError((Object _) {}),
    );
  });

  tearDownAll(() async {
    await server.close(force: true);
    await temporaryDirectory.delete(recursive: true);
  });

  test('uploadFiles sends files, parameters, headers, and progress', () async {
    var progressCallCount = 0;
    var sentBytes = 0;
    var totalBytes = 0;

    final result = await QsNetRequest.getInstance().uploadFiles(
      apiUrl: baseUri.resolve('/upload').toString(),
      files: [
        QsUploadFile(fieldName: 'files', filePath: firstFile.path),
        QsUploadFile(
          fieldName: 'files',
          filePath: secondFile.path,
          fileName: 'custom-second.txt',
        ),
      ],
      parameters: {'description': 'parameter value'},
      headers: {'x-upload-test': 'header value'},
      isShowLoading: false,
      onSendProgress: (int sent, int total) {
        progressCallCount++;
        sentBytes = sent;
        totalBytes = total;
      },
    );

    expect(result?['success'], isTrue);
    expect(result?['header'], 'header value');
    expect(result?['fileFieldCount'], 2);
    expect(result?['hasFirstFile'], isTrue);
    expect(result?['hasSecondFile'], isTrue);
    expect(result?['hasCustomFileName'], isTrue);
    expect(result?['hasParameter'], isTrue);
    expect(progressCallCount, greaterThan(0));
    expect(sentBytes, totalBytes);
    expect(totalBytes, greaterThan(0));
  });

  test('uploadFiles returns an empty map for an empty response', () async {
    final result = await QsNetRequest.getInstance().uploadFiles(
      apiUrl: baseUri.resolve('/empty').toString(),
      files: [QsUploadFile(fieldName: 'file', filePath: firstFile.path)],
      isShowLoading: false,
    );

    expect(result, isEmpty);
  });

  test('uploadFiles reports a data parse error', () async {
    QsNetRequestError? receivedError;

    final result = await QsNetRequest.getInstance().uploadFiles(
      apiUrl: baseUri.resolve('/invalid').toString(),
      files: [QsUploadFile(fieldName: 'file', filePath: firstFile.path)],
      isShowLoading: false,
      onError: (QsNetRequestError error) {
        receivedError = error;
      },
    );

    expect(result, isNull);
    expect(receivedError?.code, QsNetRequestError.dataParseError);
  });

  test('uploadFiles reports the HTTP status', () async {
    QsNetRequestError? receivedError;

    final result = await QsNetRequest.getInstance().uploadFiles(
      apiUrl: baseUri.resolve('/not-found').toString(),
      files: [QsUploadFile(fieldName: 'file', filePath: firstFile.path)],
      isShowLoading: false,
      onError: (QsNetRequestError error) {
        receivedError = error;
      },
    );

    expect(result, isNull);
    expect(receivedError?.code, HttpStatus.notFound);
  });

  test('uploadFiles reports a missing file as a Dio error', () async {
    QsNetRequestError? receivedError;

    final result = await QsNetRequest.getInstance().uploadFiles(
      apiUrl: baseUri.resolve('/upload').toString(),
      files: [
        QsUploadFile(
          fieldName: 'file',
          filePath: '${temporaryDirectory.path}/missing.txt',
        ),
      ],
      isShowLoading: false,
      onError: (QsNetRequestError error) {
        receivedError = error;
      },
    );

    expect(result, isNull);
    expect(receivedError?.code, QsNetRequestError.dioError);
  });

  test('cancelUpload cancels the selected upload', () async {
    final largeFile = await File(
      '${temporaryDirectory.path}/large.bin',
    ).writeAsBytes(List<int>.filled(5 * 1024 * 1024, 1));
    final cancelToken = CancelToken();
    QsNetRequestError? receivedError;

    final result = await QsNetRequest.getInstance().uploadFiles(
      apiUrl: baseUri.resolve('/slow-upload').toString(),
      files: [QsUploadFile(fieldName: 'file', filePath: largeFile.path)],
      isShowLoading: false,
      cancelToken: cancelToken,
      onSendProgress: (int sent, int total) {
        if (sent > 0 && !cancelToken.isCancelled) {
          QsNetRequest.getInstance().cancelUpload(
            cancelToken: cancelToken,
            reason: 'cancel upload test',
          );
        }
      },
      onError: (QsNetRequestError error) {
        receivedError = error;
      },
    );

    expect(result, isNull);
    expect(receivedError?.code, QsNetRequestError.dioError);
    expect(cancelToken.isCancelled, isTrue);
  });

  test('cancelUpload safely ignores an already cancelled token', () {
    final cancelToken = CancelToken();
    final request = QsNetRequest.getInstance();

    request.cancelUpload(
      cancelToken: cancelToken,
      reason: 'first cancellation',
    );
    request.cancelUpload(
      cancelToken: cancelToken,
      reason: 'second cancellation',
    );

    expect(cancelToken.cancelError?.error, 'first cancellation');
  });
}
