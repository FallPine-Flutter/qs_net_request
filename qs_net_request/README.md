# qs_net_request

`qs_net_request` 是一个基于 `dio` 封装的 Flutter 网络请求插件，支持 GET、POST、文件下载和多文件上传，并内置加载提示、进度监听、主动取消、日志输出和统一错误回调。

## 功能

- 支持 GET JSON 数据
- 支持 GET 字符串数据
- 支持 POST JSON 数据
- 支持文件下载、进度监听和主动取消
- 支持多文件上传、进度监听和主动取消
- 支持自定义请求参数和请求头
- 支持连接超时、接收超时配置
- 支持请求失败、数据解析失败、Dio 异常回调
- 请求时可自动展示和关闭 `qs_toast` loading

## 安装

在项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  qs_net_request: ^1.0.1
```

然后执行：

```bash
flutter pub get
```

## 引入

```dart
import 'package:qs_net_request/qs_net_request.dart';
import 'package:qs_net_request/qs_net_request_error.dart';
```

`qs_net_request.dart` 已导出 `CancelToken` 和 `QsUploadFile`，下载或上传文件时无需额外导入 `dio`。

## 初始化

建议通过单例获取请求对象：

```dart
final QsNetRequest request = QsNetRequest.getInstance();
```

插件默认超时时间为 30 秒。如需自定义超时时间，可以在应用启动后配置：

```dart
final QsNetRequest request = QsNetRequest.getInstance();

request.config(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
);
```

## GET 请求 JSON

```dart
final Map<String, dynamic>? result = await QsNetRequest.getInstance().getJson(
  'https://example.com/api/user',
  parameters: {
    'id': 1,
  },
  headers: {
    'Authorization': 'Bearer token',
  },
  onError: (QsNetRequestError error) {
    print(error);
  },
);
```

返回值说明：

- 请求成功且响应数据为 JSON 对象时，返回 `Map<String, dynamic>`
- 响应数据为空时，返回空 Map
- 请求失败或数据解析失败时，返回 `null`，并触发 `onError`

## GET 请求字符串

```dart
final String? result = await QsNetRequest.getInstance().getString(
  'https://example.com/api/text',
  parameters: {
    'keyword': 'flutter',
  },
  isShowLoading: false,
  onError: (QsNetRequestError error) {
    print(error);
  },
);
```

返回值说明：

- 请求成功且响应数据为字符串时，返回 `String`
- 响应数据为空时，返回空字符串
- 请求失败或数据解析失败时，返回 `null`，并触发 `onError`

## POST 请求 JSON

```dart
final Map<String, dynamic>? result = await QsNetRequest.getInstance().postJson(
  'https://example.com/api/login',
  parameters: {
    'account': 'demo',
    'password': '123456',
  },
  headers: {
    'Content-Type': 'application/json',
  },
  onError: (QsNetRequestError error) {
    print(error);
  },
);
```

`postJson` 会将 `parameters` 通过 `jsonEncode` 转为 JSON 字符串后提交。

## 下载文件

```dart
import 'package:qs_net_request/qs_net_request.dart';
import 'package:qs_net_request/qs_net_request_error.dart';

final CancelToken cancelToken = CancelToken();
final String? filePath = await QsNetRequest.getInstance().downloadFile(
  apiUrl: 'https://example.com/files/demo.zip',
  savePath: '/path/to/demo.zip',
  headers: {
    'Authorization': 'Bearer token',
  },
  isShowLoading: false,
  cancelToken: cancelToken,
  onReceiveProgress: (int received, int total) {
    if (total > 0) {
      final double progress = received / total;
      print('下载进度: ${(progress * 100).toStringAsFixed(0)}%');
    }
  },
  onError: (QsNetRequestError error) {
    print(error);
  },
);

// 需要取消下载时调用：
QsNetRequest.getInstance().cancelDownload(
  cancelToken: cancelToken,
  reason: '用户取消下载',
);
```

下载成功时返回 `savePath`，失败或取消时返回 `null`。失败或取消产生的残缺文件会自动删除。调用前需要确保 `savePath` 的父目录存在且可写。

每个下载任务应创建独立的 `CancelToken`。令牌取消后不能复用，重新下载时需要创建新令牌。

## 上传文件

```dart
final CancelToken cancelToken = CancelToken();
final Map<String, dynamic>? result =
    await QsNetRequest.getInstance().uploadFiles(
  apiUrl: 'https://example.com/files/upload',
  files: [
    QsUploadFile(
      fieldName: 'files',
      filePath: '/path/to/first.jpg',
    ),
    QsUploadFile(
      fieldName: 'files',
      filePath: '/path/to/second.jpg',
      fileName: 'custom-second.jpg',
    ),
  ],
  parameters: {
    'description': '示例文件',
  },
  isShowLoading: false,
  cancelToken: cancelToken,
  onSendProgress: (int sent, int total) {
    if (total > 0) {
      final double progress = sent / total;
      print('上传进度: ${(progress * 100).toStringAsFixed(0)}%');
    }
  },
  onError: (QsNetRequestError error) {
    print(error);
  },
);

// 需要取消上传时调用：
QsNetRequest.getInstance().cancelUpload(
  cancelToken: cancelToken,
  reason: '用户取消上传',
);
```

多个 `QsUploadFile` 可以使用同一个 `fieldName`。`fileName` 未设置时会自动使用本地文件名。上传成功时返回服务端的 JSON 对象，响应为空时返回空 Map，失败或取消时返回 `null`。

`QsUploadFile` 参数说明：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `fieldName` | 是 | multipart 表单中的文件字段名，多个文件可使用同一个字段名 |
| `filePath` | 是 | 待上传文件的本地路径 |
| `fileName` | 否 | 发送给服务端的文件名，未设置时使用本地文件名 |

每个上传任务应创建独立的 `CancelToken`。令牌取消后不能复用，重新上传时需要创建新令牌。

## Loading 控制

所有请求方法默认会自动展示 loading：

```dart
isShowLoading: true
```

如果当前页面需要自己控制加载状态，可以关闭自动 loading：

```dart
final Map<String, dynamic>? result = await QsNetRequest.getInstance().getJson(
  'https://example.com/api/list',
  isShowLoading: false,
);
```

## 错误处理

请求失败时可以通过 `onError` 获取 `QsNetRequestError`：

```dart
await QsNetRequest.getInstance().getJson(
  'https://example.com/api/data',
  onError: (QsNetRequestError error) {
    print('code: ${error.code}');
    print('message: ${error.message}');
  },
);
```

内置错误码：

| 错误码 | 说明 |
| --- | --- |
| `QsNetRequestError.dataParseError` / `-10000` | 数据解析失败 |
| `QsNetRequestError.dioError` / `-10001` | Dio 请求异常、文件读写失败或任务取消 |
| HTTP 状态码 | 服务端返回非 200 状态 |

## API 参数

### getJson

```dart
Future<Map<String, dynamic>?> getJson(
  String apiUrl, {
  Map<String, dynamic>? parameters,
  Map<String, dynamic>? headers,
  bool isShowLoading = true,
  void Function(QsNetRequestError error)? onError,
})
```

### getString

```dart
Future<String?> getString(
  String apiUrl, {
  Map<String, dynamic>? parameters,
  Map<String, dynamic>? headers,
  bool isShowLoading = true,
  void Function(QsNetRequestError error)? onError,
})
```

### postJson

```dart
Future<Map<String, dynamic>?> postJson(
  String apiUrl, {
  Map<String, dynamic>? parameters,
  Map<String, dynamic>? headers,
  bool isShowLoading = true,
  void Function(QsNetRequestError error)? onError,
})
```

### downloadFile

```dart
Future<String?> downloadFile({
  required String apiUrl,
  required String savePath,
  Map<String, dynamic>? parameters,
  Map<String, dynamic>? headers,
  bool isShowLoading = true,
  void Function(int received, int total)? onReceiveProgress,
  CancelToken? cancelToken,
  void Function(QsNetRequestError error)? onError,
})
```

### cancelDownload

```dart
void cancelDownload({
  required CancelToken cancelToken,
  String reason = '取消下载',
})
```

`cancelDownload` 只取消对应 `CancelToken` 的下载任务。重复调用同一个令牌不会重复取消，也不会影响其他并发下载。

### uploadFiles

```dart
Future<Map<String, dynamic>?> uploadFiles({
  required String apiUrl,
  required List<QsUploadFile> files,
  Map<String, dynamic>? parameters,
  Map<String, dynamic>? headers,
  bool isShowLoading = true,
  void Function(int sent, int total)? onSendProgress,
  CancelToken? cancelToken,
  void Function(QsNetRequestError error)? onError,
})
```

### cancelUpload

```dart
void cancelUpload({
  required CancelToken cancelToken,
  String reason = '取消上传',
})
```

`cancelUpload` 只取消对应 `CancelToken` 的上传任务。重复调用同一个令牌不会重复取消，也不会影响其他并发上传。

## 注意事项

- 当前只有 HTTP 状态码为 `200` 时会被视为请求成功。
- `getJson` 和 `postJson` 要求响应数据为 JSON 对象。
- `getString` 要求响应数据为字符串。
- `downloadFile` 会覆盖目标路径下已有的同名文件，不会自动创建父目录。
- `uploadFiles` 使用 `multipart/form-data`，调用方需要确保文件存在且可读。
- `downloadFile` 和 `uploadFiles` 的进度回调中，服务端未提供总长度时 `total` 可能小于或等于 `0`，计算百分比前应先判断。
- 当前不支持断点续传、后台传输、自动重试或上传下载队列。
- 自动 loading 依赖 `qs_toast`，请求结束或异常时会自动调用 `QsToast.dismiss()`。
