import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/auth/user.dart';

/// 이 컨테이너가 **누구 몫의 데이터**를 들고 있는지 기억한다.
///
/// 앱은 로그인한 사람의 데이터만 중계한다 — 한 로그인 앞으로 받아 둔 것이 다른
/// 로그인에게 보이면 안 된다. 그래서 인증 상태가 바뀔 때마다 "지금 들어온 사람이
/// 앞사람과 같은가" 를 여기서 가리고, 다르면 부르는 쪽이 컨테이너를 통째로 새로
/// 만든다(`SessionScope`).
///
/// 주인은 `rowId` 로 가린다. 표시 이름·이메일은 같은 사람이어도 바뀐다.
class SessionOwner {
  int? _rowId;

  /// [auth] 가 **앞사람과 다른 사람**의 로그인이면 `true`.
  ///
  /// - **확정된 값만 센다.** 확인 중·실패는 아직 누구인지 모르는 상태다. riverpod 은
  ///   다시 확인하는 동안에도 이전 값을 들고 있어서(`isLoading && hasValue`) 값만 보면
  ///   로그인 도중의 중간 상태가 "앞사람이 또 들어왔다" 로 읽힌다.
  /// - **로그아웃은 주인을 바꾸지 않는다.** 받아 둔 것은 여전히 앞사람 몫이고, 로그인
  ///   화면은 그걸 읽지 않는다. 같은 사람이 다시 들어오면 그대로 이어 쓴다 — 여기서
  ///   주인을 비우면 그다음에 들어오는 **다른 사람**을 "첫 로그인" 으로 잘못 읽는다.
  /// - **이 컨테이너의 첫 로그인은 바뀐 게 아니다.** 받아 둔 것이 아직 없다.
  bool replacedBy(AsyncValue<User?> auth) {
    if (auth.isLoading || auth.hasError) return false;
    final next = auth.value?.rowId;
    if (next == null) return false;
    final prev = _rowId;
    _rowId = next;
    return prev != null && prev != next;
  }
}

/// 컨테이너마다 하나. "누구 몫을 들고 있는가" 는 화면이 아니라 **컨테이너의 성질**이다 —
/// 컨테이너가 새로 만들어지면 주인도 처음부터 다시 센다.
final sessionOwnerProvider = Provider<SessionOwner>((ref) => SessionOwner());
