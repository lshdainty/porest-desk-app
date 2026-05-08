import 'card_catalog.dart';

/// 카드 카탈로그 페이지 — Spring Page 응답을 클라이언트 측에서 사용하는 형태로 풀어냄.
class CardCatalogPage {
  const CardCatalogPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number, // 0-based
    required this.size,
    required this.first,
    required this.last,
    required this.empty,
  });

  final List<CardCatalogSummary> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;
  final bool empty;

  factory CardCatalogPage.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List?) ?? const [];
    // 백엔드는 page 메타를 별도 'meta' 객체에 담아 보냄 (front PageResponse 동일).
    // 구버전 호환 위해 top-level 도 fallback 으로 둔다.
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    int? metaInt(String k) {
      final v = meta[k] ?? json[k];
      return (v as num?)?.toInt();
    }
    bool? metaBool(String k) {
      final v = meta[k] ?? json[k];
      return v as bool?;
    }
    return CardCatalogPage(
      content: content
          .map((e) => CardCatalogSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      totalElements: metaInt('totalElements') ?? 0,
      totalPages: metaInt('totalPages') ?? 0,
      // 백엔드 meta 는 number 대신 'page' 를 사용.
      number: metaInt('page') ?? metaInt('number') ?? 0,
      size: metaInt('size') ?? 0,
      first: metaBool('first') ?? true,
      last: metaBool('last') ?? true,
      empty: metaBool('empty') ?? content.isEmpty,
    );
  }
}
