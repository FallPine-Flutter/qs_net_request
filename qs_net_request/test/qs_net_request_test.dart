import 'package:flutter_test/flutter_test.dart';
import 'package:qs_net_request/qs_net_request.dart';
import 'package:qs_net_request/qs_net_request_platform_interface.dart';
import 'package:qs_net_request/qs_net_request_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockQsNetRequestPlatform
    with MockPlatformInterfaceMixin
    implements QsNetRequestPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final QsNetRequestPlatform initialPlatform = QsNetRequestPlatform.instance;

  test('$MethodChannelQsNetRequest is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQsNetRequest>());
  });

  test('getPlatformVersion', () async {
    QsNetRequest qsNetRequestPlugin = QsNetRequest();
    MockQsNetRequestPlatform fakePlatform = MockQsNetRequestPlatform();
    QsNetRequestPlatform.instance = fakePlatform;

    expect(await qsNetRequestPlugin.getPlatformVersion(), '42');
  });
}
