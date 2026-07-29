import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qs_net_request_method_channel.dart';

abstract class QsNetRequestPlatform extends PlatformInterface {
  /// Constructs a QsNetRequestPlatform.
  QsNetRequestPlatform() : super(token: _token);

  static final Object _token = Object();

  static QsNetRequestPlatform _instance = MethodChannelQsNetRequest();

  /// The default instance of [QsNetRequestPlatform] to use.
  ///
  /// Defaults to [MethodChannelQsNetRequest].
  static QsNetRequestPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QsNetRequestPlatform] when
  /// they register themselves.
  static set instance(QsNetRequestPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
