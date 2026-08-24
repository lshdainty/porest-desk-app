// 서버 UserAgentParser 가 아는 형태로 나가는지 — 형태가 틀어지면 목록이
// 전부 "알 수 없는 기기" 가 된다.
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:porest_desk_app/core/network/user_agent.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Porest',
      packageName: 'com.porest.desk',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  test('Porest/<버전> 으로 시작한다 — 서버가 이 접두로 앱을 가른다', () async {
    expect(await buildUserAgent(), startsWith('Porest/1.2.3'));
  });

  test('플랫폼을 괄호에 담는다 — 서버가 "(ios"·"android" 로 기기를 가른다', () async {
    final ua = await buildUserAgent();
    // 테스트는 호스트(리눅스)에서 도므로 Linux 로 나온다. 형태만 고정한다.
    expect(ua, matches(r'^Porest/1\.2\.3 \(.+\)$'));
  });
}
