# qs_net_request

`qs_net_request` 是一个基于 `dio` 封装的 Flutter 网络请求插件，内置加载提示、日志输出和统一错误回调，适合项目中快速发起常见的 GET、POST 请求。

## 功能

- 支持 GET JSON 数据
- 支持 GET 字符串数据
- 支持 POST JSON 数据
- 支持自定义请求参数和请求头
- 支持连接超时、接收超时配置
- 支持请求失败、数据解析失败、Dio 异常回调
- 请求时可自动展示和关闭 `qs_toast` loading

## 安装

在项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  qs_net_request: ^1.0.0
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
| `QsNetRequestError.dioError` / `-10001` | Dio 请求异常 |
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

## 注意事项

- 当前只有 HTTP 状态码为 `200` 时会被视为请求成功。
- `getJson` 和 `postJson` 要求响应数据为 JSON 对象。
- `getString` 要求响应数据为字符串。
- 自动 loading 依赖 `qs_toast`，请求结束或异常时会自动调用 `QsToast.dismiss()`。
