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
    return CardCatalogPage(
      content: content
          .map((e) => CardCatalogSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      first: (json['first'] as bool?) ?? true,
      last: (json['last'] as bool?) ?? true,
      empty: (json['empty'] as bool?) ?? content.isEmpty,
    );
  }
}
