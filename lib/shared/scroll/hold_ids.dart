import 'dart:async';

import 'package:flutter/foundation.dart';

/// 낙관 갱신으로 목록에서 빠질(또는 자리를 옮길) 항목을 그 자리에 잠깐 붙들어 두는 시간.
///
/// 따닥 막기(600ms)보다 **길어야** 한다 — 재누름 방어가 풀린 뒤에도 줄이 남아 있어야 두 번째 누름이 (이미 끝낸) 같은 줄에
/// 떨어진다. 두 값의 대소가 뒤집히면 방어에 틈이 생긴다(웹 `LIST_HOLD_MS` 와 같은 값).
const Duration kListHold = Duration(milliseconds: 700);

/// 항목별 자리 유지 — 완료 누름처럼 **누른 즉시 목록에서 빠지거나 아래로 가는** 항목이 대상이다(웹 `useHoldIds`).
///
/// 완료를 따닥 누르면 다른 할 일까지 완료됐다(QA #29). 첫 누름의 낙관 갱신이 그 줄을 곧바로 옮기고 아래 줄이 같은 자리로
/// 올라와, 두 번째 누름이 **다음 항목**을 끝냈다. 요청이 끝나는 때가 아니라 고정 시간으로 푼다 — 통신이 빠르면 잠금이 100ms 만에
/// 풀려 두 번째 누름이 그 뒤에 오기 때문이다. 바뀌면 [ChangeNotifier] 로 알린다(화면이 `setState`).
class HoldIds extends ChangeNotifier {
  HoldIds({this.duration = kListHold});

  final Duration duration;
  final Set<int> _ids = {};
  final Map<int, Timer> _timers = {};
  bool _disposed = false;

  Set<int> get ids => Set.unmodifiable(_ids);
  bool contains(int id) => _ids.contains(id);

  void hold(int id) {
    _timers[id]?.cancel();
    if (_ids.add(id)) notifyListeners();
    _timers[id] = Timer(duration, () {
      _timers.remove(id);
      if (_disposed) return;
      if (_ids.remove(id)) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
