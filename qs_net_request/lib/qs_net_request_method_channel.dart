import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qs_net_request_platform_interface.dart';

/// An implementation of [QsNetRequestPlatform] that uses method channels.
class MethodChannelQsNetRequest extends QsNetRequestPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qs_net_request');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
