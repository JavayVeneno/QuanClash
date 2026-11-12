import 'dart:io';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuanClashHttpOverrides extends HttpOverrides {
  static String handleFindProxy(Uri url) {
    final proxy = _proxyFor(url);
    commonPrint.log('find $url proxy: ${proxy != 'DIRECT'}');
    return proxy;
  }

  /// 当前是否会把 [url] 交给本地内核代理，不写日志。
  ///
  /// 请求层用它判断一次失败是否值得再走直连重试。
  static bool isProxied(Uri url) => _proxyFor(url).startsWith('PROXY');

  static String _proxyFor(Uri url) {
    if ([localhost].contains(url.host)) {
      return 'DIRECT';
    }
    final ref = globalState.container;
    final isStart = ref.read(isStartProvider);
    final suspend = ref.read(suspendProvider);
    if (!isStart || suspend) return 'DIRECT';
    final mixedPort = ref.read(
      patchClashConfigProvider.select((state) => state.mixedPort),
    );
    return 'PROXY localhost:$mixedPort';
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    client.findProxy = handleFindProxy;
    return client;
  }
}
