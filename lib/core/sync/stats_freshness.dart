import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 60초 규칙이 함께 미는 조회들의 **마지막 성공 조회 시각** 한 칸.
///
/// 통계 탭은 셸(`IndexedStack`)에 상주하고 provider 도 autoDispose 가 아니라,
/// 진입할 때 비우지 않으면 다른 기기에서 넣은 값이 안 보인다. 그렇다고 들어올
/// 때마다 비우면 탭을 두 번 왕복하는 것만으로 네 번씩 조회가 나간다.
///
/// 그래서 웹(react-query `staleTime` 60초)과 **같은 규칙**을 쓴다 — 마지막으로
/// 받아 온 지 60초가 지났을 때만 다시 받는다. 기준은 "마지막으로 **비운** 시각"
/// 이 아니라 **"마지막으로 값을 받아 온 시각"** 이다. 무효화는 아무도 그 provider 를
/// 보고 있지 않으면 조회로 이어지지 않으므로, 비운 시각을 기준으로 삼으면 한 번도
/// 받지 않은 채 60초가 흘러가 버린다.
///
/// 시각은 **provider 가 값을 만들어 낸 직후**에만 찍는다(실패하면 안 찍는다).
/// 타이머·폴링은 없다 — 화면에 들어올 때 [isStaleAt] 으로 비교만 한다.
///
/// provider 마다 칸을 두지 않고 **가장 최근 것 하나**만 든다. 이 조회들은 함께
/// 움직인다 — [invalidateAfterExpenseChange] · 당겨서 새로고침 · 진입 갱신이
/// 모두 한 묶음으로 밀고, 무효화도 한 묶음으로 한다. 아직 한 번도 안 받은
/// 것(예: 열어 본 적 없는 탭)은 여기 안 남는데, 안 읽힌 provider 를 비우는
/// 것은 no-op 이라 그대로 두어도 손해가 없다.
///
/// 그래서 **비우는 자리와 시각을 남기는 자리는 같은 목록**이어야 한다. 한쪽에만
/// 넣으면 그 provider 만 기준이 달라진다 — 비우기만 하면 스스로 받은 직후에도
/// stale 로 읽히고, 시각만 남기면 남의 시계를 밀어 정작 자신은 안 갱신된다.
class StatsFreshness {
  /// 웹 `staleTime` 과 같은 값.
  static const Duration ttl = Duration(seconds: 60);

  /// 마지막 성공 조회 시각. 한 번도 받은 적이 없으면 `null`.
  DateTime? _lastFetchedAt;

  /// 통계 provider 가 값을 만들어 냈다. 뒤로 가는 시계(수동 변경·DST)에도
  /// 기준이 미래에 박히지 않도록 **더 최근 것만** 남긴다.
  void markFetched(DateTime at) {
    final prev = _lastFetchedAt;
    if (prev == null || at.isAfter(prev)) _lastFetchedAt = at;
  }

  /// [now] 기준으로 다시 받아야 하는가.
  ///
  /// 한 번도 안 받았으면 `true` — 비워도 no-op 이니 그냥 비운다.
  /// 경계는 웹 react-query 와 같게 **`>=`** 다(정확히 60초면 stale).
  bool isStaleAt(DateTime now) {
    final last = _lastFetchedAt;
    if (last == null) return true;
    return now.difference(last) >= ttl;
  }
}

/// 앱 세션 동안 유지되는 한 칸 — 화면을 다시 그릴 일이 없어 알림도 필요 없다.
/// (`Notifier` 로 두면 provider 가 값을 만드는 도중 상태를 바꾸게 되어 되레 위험하다.)
final statsFreshnessProvider = Provider<StatsFreshness>(
  (ref) => StatsFreshness(),
);

/// 시계 — 테스트가 진짜 60초를 기다리지 않도록 갈아 끼운다.
final statsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

extension StatsFreshnessRef on Ref {
  /// 통계 provider 가 값을 **성공적으로** 만든 직후 호출한다.
  /// (`await` 뒤에 두어야 실패한 조회가 시각을 갱신하지 않는다.)
  void markStatsFetched() =>
      read(statsFreshnessProvider).markFetched(read(statsClockProvider)());
}
