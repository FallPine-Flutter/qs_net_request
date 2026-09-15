import 'package:flutter_test/flutter_test.dart';
import 'package:qs_net_request/qs_net_request_platform_interface.dart';
import 'package:qs_net_request/qs_net_request_method_channel.dart';

void main() {
  final QsNetRequestPlatform initialPlatform = QsNetRequestPlatform.instance;

  test('$MethodChannelQsNetRequest is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQsNetRequest>());
  });
}
