import 'package:quanclash/common/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts public https endpoints, including an ip placeholder', () {
    for (final value in [
      'https://ip.net.coffee/api/iprisk/{ip}',
      'https://ip.net.coffee/claude/',
      'https://example.com',
      'https://example.com/check?ip={ip}',
      'https://example.com:443/check',
    ]) {
      expect(utils.isValidRiskApiUrl(value), isTrue, reason: value);
    }
  });

  test('rejects non-https, local and malformed endpoints', () {
    for (final value in [
      'http://ip.net.coffee/api/iprisk/{ip}',
      'https://ip.net.coffee:8443/api',
      'https://localhost/api',
      'https://127.0.0.1/api',
      'https://10.0.0.1/api',
      'https://192.168.1.1/api',
      'https://[::1]/api',
      'https://${'user'}:${'pass'}@example.com/api',
      'https://example.com/api#fragment',
      'https://example.com/../api',
      'not a url',
      '',
    ]) {
      expect(utils.isValidRiskApiUrl(value), isFalse, reason: value);
    }
  });
}
