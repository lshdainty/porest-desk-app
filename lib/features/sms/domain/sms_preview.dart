/// 수신함 목록에 보여 줄 최소 정보 — 원문을 가볍게 훑은 결과.
///
/// 진짜 파싱은 서버가 한다(가맹점·카드·카테고리·일시까지). 여기서는 목록에서
/// "이게 무슨 결제였는지" 알아볼 만큼만, 네트워크 없이 로컬에서 뽑는다.
/// 못 뽑으면 원문을 그대로 보여 주면 되므로 완벽할 필요는 없다.
class SmsPreview {
  const SmsPreview({this.amount, this.merchant, this.issuer});

  /// 결제 금액(원). 못 읽으면 null.
  final int? amount;

  /// 가맹점명. 못 읽으면 null — 이때 목록은 원문 축약으로 대체한다.
  final String? merchant;

  /// 발신 기관(토스·신한카드 등). 첫 줄이 기관명인 경우가 많다.
  final String? issuer;

  static final RegExp _amount = RegExp(r'([0-9][0-9,]{0,15})\s*원');

  /// 금액 앞에 붙으면 결제액이 아닌 말들 — 서버 파서와 같은 뜻.
  static const List<String> _amountNoise = [
    '누적',
    '잔액',
    '한도',
    '합계',
    '사용가능',
    '가용',
    '잔여',
    '총',
    '출금가능',
  ];

  /// 가맹점 자리로 볼 수 없는 말이 들어간 줄 — 카드사·상태·시각 줄.
  static const List<String> _nonMerchantMarkers = [
    '승인',
    '취소',
    '결제',
    '일시불',
    '할부',
    '체크',
    '신용',
    '누적',
    '잔액',
    '한도',
    '사용',
    '출금',
    '입금',
  ];

  /// 원문을 훑어 목록용 미리보기를 만든다.
  static SmsPreview of(String text) {
    final normalized = text
        .replaceAll('[Web발신]', '')
        .replaceAll('[web발신]', '')
        .trim();
    final lines = normalized
        .split(RegExp(r'\R'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return SmsPreview(
      amount: _findAmount(normalized),
      merchant: _findMerchant(lines),
      issuer: _findIssuer(lines),
    );
  }

  static int? _findAmount(String text) {
    for (final m in _amount.allMatches(text)) {
      final from = (m.start - 8).clamp(0, text.length);
      final before = text.substring(from, m.start);
      if (_amountNoise.any(before.contains)) continue;
      final digits = m.group(1)!.replaceAll(',', '');
      final value = int.tryParse(digits);
      if (value != null && value > 0) return value;
    }
    return null;
  }

  /// 가맹점 — 파이프(`|`) 뒤가 가맹점인 포맷(토스 등)을 먼저 본다.
  ///
  /// 그게 아니면 상태·금액·시각 줄을 걷어낸 마지막 의미 있는 줄을 쓴다
  /// (카드사 문자는 가맹점이 맨 끝에 오는 경우가 압도적이다).
  static String? _findMerchant(List<String> lines) {
    for (final line in lines.reversed) {
      if (line.contains('|')) {
        final tail = line.split('|').last.trim();
        if (_isMerchantLike(tail)) return tail;
      }
    }
    for (final line in lines.reversed) {
      if (_isMerchantLike(line)) return line;
    }
    return null;
  }

  static final RegExp _timeLike = RegExp(r'\d{1,2}[:/]\d{2}');

  static bool _isMerchantLike(String line) {
    if (line.isEmpty) return false;
    // 글자가 있어야 가맹점 — 숫자·기호만 남은 줄(금액·시각 잔여물)은 뺀다.
    if (!RegExp(r'[가-힣A-Za-z]').hasMatch(line)) return false;
    if (_amount.hasMatch(line)) return false;
    // 시각·카드번호 줄("카드(6678) | 08/14 19:09")은 가맹점이 아니다.
    if (_timeLike.hasMatch(line)) return false;
    if (RegExp(r'카드\s*\(?\d{4}').hasMatch(line)) return false;
    final lower = line.toLowerCase();
    if (_nonMerchantMarkers.any(lower.contains)) return false;
    return true;
  }

  /// 발신 기관 — 첫 줄이 기관명(토스·신한카드)인 경우가 많다.
  static String? _findIssuer(List<String> lines) {
    if (lines.isEmpty) return null;
    final first = lines.first;
    // 첫 줄에 금액·시각이 섞였으면 기관명 줄이 아니다.
    if (_amount.hasMatch(first)) return null;
    if (RegExp(r'\d{1,2}[:/]\d{2}').hasMatch(first)) return null;
    if (first.length > 12) return null;
    return first;
  }
}
