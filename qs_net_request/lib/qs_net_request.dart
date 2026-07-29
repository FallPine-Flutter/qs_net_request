import 'dart:convert';

import 'package:qs_log/qs_log.dart';
import 'package:qs_net_request/qs_net_request_error.dart';
import 'package:qs_toast/qs_toast.dart';
import 'package:dio/dio.dart' as net_request;
import 'qs_net_request_platform_interface.dart';

class QsNetRequest {
  Future<String?> getPlatformVersion() {
    return QsNetRequestPlatform.instance.getPlatformVersion();
  }

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
