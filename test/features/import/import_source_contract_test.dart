import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/features/import/presentation/import_view.dart';

void main() {
  // 서버 ImportSource enum 이름. 이름 바꾸기에서 문구처럼 "그루" 로 바뀌어 400 이 난 적이 있다.
  test('가져오기 출처는 서버 enum 이름으로 보낸다', () {
    expect(importSources, [
      'POREST',
      'EASYBUDGET',
      'BANKSALAD',
      'TOSS',
      'CUSTOM',
    ]);
  });
}
