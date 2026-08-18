import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 단일 인스턴스 Provider.
///
/// `await ref.read(prefsProvider.future)` 로 접근. 첫 호출 후엔 동기 캐시 사용.
final prefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// porest-desk-front 와 동일한 키를 그대로 사용 — 추후 동기화 정책 변경 쉽게.
abstract final class PrefsKeys {
  static const themeMode = 'vite-ui-theme';   // 'light' | 'dark' | 'system'
  static const currency = 'pd-currency';      // 'KRW' | 'USD' | 'EUR' | 'JPY'
  /// 예전 단일 스위치(bool). 한 번 읽어 카드 전체로 펼치고 지운다.
  static const hideAmounts = 'pd-hide';       // bool (legacy)
  static const hideCards = 'pd-hide-cards';   // List<String>
  static const locale = 'pd-locale';          // 'ko' | 'en' | null(=system)
  /// 전체 화면 업데이트 안내를 건너뛴 빌드번호. 이 빌드는 다시 안 띄운다(강제는 무시).
  static const updateSkippedBuild = 'pd-update-skipped-build'; // int
}
