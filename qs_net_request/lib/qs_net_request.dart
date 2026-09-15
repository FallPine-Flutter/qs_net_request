import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as net_request;
import 'package:dio/dio.dart' show CancelToken;
import 'package:qs_log/qs_log.dart';
import 'package:qs_net_request/qs_net_request_error.dart';
import 'package:qs_net_request/qs_upload_file.dart';
import 'package:qs_toast/qs_toast.dart';

export 'package:dio/dio.dart' show CancelToken;
export 'package:qs_net_request/qs_upload_file.dart';

class QsNetRequest {
  /// Func
  /// 配置
  void config({
    required Duration? connectTimeout,
    required Duration? receiveTimeout,
  }) {
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
  }

  /// Get JSON 数据
  Future<Map<String, dynamic>?> getJson(
    String apiUrl, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? headers,
    bool isShowLoading = true,
    void Function(QsNetRequestError error)? onError,
  }) async {
    if (isShowLoading) {
      QsToast.loading();
    }
    Map<String, dynamic> newHeaders = headers ?? {};

    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: parameters,
        options: net_request.Options(
          headers: newHeaders,
          responseType: net_request.ResponseType.json,
        ),
      );

      if (isShowLoading) {
        QsToast.dismiss();
      }

      if (response.statusCode == 200) {
        if (response.data == null) {
          return {};
        } else if (response.data is Map<dynamic, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          QsLog.error("数据解析失败");
          onError?.call(
            QsNetRequestError(
              code: QsNetRequestError.dataParseError,
              message: "数据解析失败",
            ),
          );
          return null;
        }
      } else {
        QsLog.error("网络请求失败: ${response.statusCode} ${response.statusMessage}");
        onError?.call(
          QsNetRequestError(
            code: response.statusCode,
            message: response.statusMessage ?? "",
          ),
        );
        return null;
      }
    } catch (e) {
      if (isShowLoading) {
        QsToast.dismiss();
      }

      QsLog.error("dio异常: $e");
      onError?.call(
        QsNetRequestError(
          code: QsNetRequestError.dioError,
          message: "dio异常: $e",
        ),
      );
      return null;
    }
  }

  /// Get 字符串数据
  Future<String?> getString(
    String apiUrl, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? headers,
    bool isShowLoading = true,
    void Function(QsNetRequestError error)? onError,
  }) async {
    if (isShowLoading) {
      QsToast.loading();
    }
    Map<String, dynamic> newHeaders = headers ?? {};

    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: parameters,
        options: net_request.Options(
          headers: newHeaders,
          responseType: net_request.ResponseType.json,
        ),
      );

      if (isShowLoading) {
        QsToast.dismiss();
      }

      if (response.statusCode == 200) {
        if (response.data == null) {
          return "";
        } else if (response.data is String) {
          return response.data as String;
        } else {
          QsLog.error("数据解析失败");
          onError?.call(
            QsNetRequestError(
              code: QsNetRequestError.dataParseError,
              message: "数据解析失败",
            ),
          );
          return null;
        }
      } else {
        QsLog.error("网络请求失败: ${response.statusCode} ${response.statusMessage}");
        onError?.call(
          QsNetRequestError(
            code: response.statusCode,
            message: response.statusMessage ?? "",
          ),
        );
        return null;
      }
    } catch (e) {
      if (isShowLoading) {
        QsToast.dismiss();
      }
      QsLog.error("dio异常: $e");
      onError?.call(
        QsNetRequestError(
          code: QsNetRequestError.dioError,
          message: "dio异常: $e",
        ),
      );
      return null;
    }
  }

  /// Post JSON 数据
  Future<Map<String, dynamic>?> postJson(
    String apiUrl, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? headers,
    bool isShowLoading = true,
    void Function(QsNetRequestError error)? onError,
  }) async {
    if (isShowLoading) {
      QsToast.loading();
    }
    Map<String, dynamic> newHeaders = headers ?? {};

    try {
      final response = await _dio.post(
        apiUrl,
        data: jsonEncode(parameters),
        options: net_request.Options(
          headers: newHeaders,
          responseType: net_request.ResponseType.json,
        ),
      );

      if (isShowLoading) {
        QsToast.dismiss();
      }

      if (response.statusCode == 200) {
        if (response.data == null) {
          return {};
        } else if (response.data is Map<dynamic, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          QsLog.error("数据解析失败");
          onError?.call(
            QsNetRequestError(
              code: QsNetRequestError.dataParseError,
              message: "数据解析失败",
            ),
          );
          return null;
        }
      } else {
        QsLog.error("网络请求失败: ${response.statusCode} ${response.statusMessage}");
        onError?.call(
          QsNetRequestError(
            code: response.statusCode,
            message: response.statusMessage ?? "",
          ),
        );
        return null;
      }
    } catch (e) {
      if (isShowLoading) {
        QsToast.dismiss();
      }
      QsLog.error("dio异常: $e");
      onError?.call(
        QsNetRequestError(
          code: QsNetRequestError.dioError,
          message: "dio异常: $e",
        ),
      );
      return null;
    }
  }

  /// 下载文件
  ///
  /// 下载前创建 [CancelToken]，并将同一个令牌传给 [downloadFile]：
  ///
  /// ```dart
  /// final CancelToken cancelToken = CancelToken();
  ///
  /// await QsNetRequest.getInstance().downloadFile(
  ///   apiUrl: downloadUrl,
  ///   savePath: savePath,
  ///   cancelToken: cancelToken,
  /// );
  ///
  /// QsNetRequest.getInstance().cancelDownload(
  ///   cancelToken: cancelToken,
  ///   reason: '用户取消下载',
  /// );
  /// ```
  ///
  /// 已取消的 [CancelToken] 不能用于新的下载任务，重新下载时需要创建新令牌。
  Future<String?> downloadFile({
    required String apiUrl,
    required String savePath,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? headers,
    bool isShowLoading = true,
    void Function(int received, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    void Function(QsNetRequestError error)? onError,
  }) async {
    if (isShowLoading) {
      QsToast.loading();
    }

    try {
      final response = await _dio.download(
        apiUrl,
        savePath,
        queryParameters: parameters,
        options: net_request.Options(
          headers: headers ?? {},
          validateStatus: (_) => true,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        deleteOnError: true,
      );

      if (response.statusCode == 200) {
        return savePath;
      }

      await _deleteFile(filePath: savePath);
      final error = QsNetRequestError(
        code: response.statusCode,
        message: response.statusMessage ?? "",
      );
      QsLog.error("文件下载失败: ${error.code} ${error.message}");
      onError?.call(error);
      return null;
    } catch (e) {
      await _deleteFile(filePath: savePath);
      final error = QsNetRequestError(
        code: QsNetRequestError.dioError,
        message: "dio异常: $e",
      );
      QsLog.error(error.message);
      onError?.call(error);
      return null;
    } finally {
      if (isShowLoading) {
        QsToast.dismiss();
      }
    }
  }

  /// 取消下载
  void cancelDownload({
    required CancelToken cancelToken,
    String reason = "取消下载",
  }) {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel(reason);
    }
  }

  /// 上传文件
  ///
  /// 上传前创建 [CancelToken]，并将同一个令牌传给 [uploadFiles]：
  ///
  /// ```dart
  /// final CancelToken cancelToken = CancelToken();
  ///
  /// await QsNetRequest.getInstance().uploadFiles(
  ///   apiUrl: uploadUrl,
  ///   files: [
  ///     QsUploadFile(fieldName: 'files', filePath: firstFilePath),
  ///     QsUploadFile(fieldName: 'files', filePath: secondFilePath),
  ///   ],
  ///   cancelToken: cancelToken,
  /// );
  ///
  /// QsNetRequest.getInstance().cancelUpload(
  ///   cancelToken: cancelToken,
  ///   reason: '用户取消上传',
  /// );
  /// ```
  ///
  /// 已取消的 [CancelToken] 不能用于新的上传任务，重新上传时需要创建新令牌。
  Future<Map<String, dynamic>?> uploadFiles({
    required String apiUrl,
    required List<QsUploadFile> files,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? headers,
    bool isShowLoading = true,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
    void Function(QsNetRequestError error)? onError,
  }) async {
    if (isShowLoading) {
      QsToast.loading();
    }

    try {
      final formData = net_request.FormData.fromMap(parameters ?? {});
      for (final file in files) {
        formData.files.add(
          MapEntry(
            file.fieldName,
            await net_request.MultipartFile.fromFile(
              file.filePath,
              filename: file.fileName,
            ),
          ),
        );
      }

      final response = await _dio.post(
        apiUrl,
        data: formData,
        options: net_request.Options(
          headers: headers ?? {},
          responseType: net_request.ResponseType.json,
          validateStatus: (_) => true,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

      if (response.statusCode != 200) {
        final error = QsNetRequestError(
          code: response.statusCode,
          message: response.statusMessage ?? "",
        );
        QsLog.error("文件上传失败: ${error.code} ${error.message}");
        onError?.call(error);
        return null;
      }

      if (response.data == null || response.data == "") {
        return {};
      }
      if (response.data is Map<dynamic, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      const error = QsNetRequestError(
        code: QsNetRequestError.dataParseError,
        message: "数据解析失败",
      );
      QsLog.error(error.message);
      onError?.call(error);
      return null;
    } catch (e) {
      final error = QsNetRequestError(
        code: QsNetRequestError.dioError,
        message: "dio异常: $e",
      );
      QsLog.error(error.message);
      onError?.call(error);
      return null;
    } finally {
      if (isShowLoading) {
        QsToast.dismiss();
      }
    }
  }

  /// 取消上传
  void cancelUpload({
    required CancelToken cancelToken,
    String reason = "取消上传",
  }) {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel(reason);
    }
  }

  /// 删除下载失败后残留的文件
  Future<void> _deleteFile({required String filePath}) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      QsLog.error("下载残留文件删除失败: $e");
    }
  }

  /// Property
  static final net_request.Dio _dio = net_request.Dio();

  /// 单例
  static QsNetRequest? _instance;
  QsNetRequest._internal() {
    /// 默认配置
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }
  static QsNetRequest getInstance() {
    _instance ??= QsNetRequest._internal();
    return _instance!;
  }
}
