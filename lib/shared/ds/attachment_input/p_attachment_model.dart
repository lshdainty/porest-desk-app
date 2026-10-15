import 'package:flutter/widgets.dart';

/// 항목 상태 — 고른 직후(pending) · 올리는 중(uploading) · 올림(success) · 실패(error). 고른 직후와 올림은 같은 모습이다.
enum PAttachmentStatus { pending, uploading, success, error }

/// 거절 이유 — 형식 · 크기 · 개수. 이유마다 한 문장으로 Field 오류 글에 쓴다(문구는 호출하는 쪽이 넘긴다).
enum PAttachmentRejectionCode { invalidType, fileTooLarge, tooManyFiles }

/// 고르는 길 — 사진 찍기 · 앨범에서 고르기 · 파일 고르기. 앱의 첨부 타일 · 파일 선택은 메뉴 시트로 이 셋을 연다.
enum PAttachmentSource { camera, gallery, files }

/// 줄에 놓인 항목. 항목 목록은 쓰는 쪽이 쥔다(제어) — 올리기 요청과 상태도 쓰는 쪽이 바꾼다.
@immutable
class PAttachmentEntry {
  const PAttachmentEntry({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    this.preview,
    this.path,
    this.status = PAttachmentStatus.pending,
    this.progress,
  });

  final String id;
  final String name;

  /// 바이트.
  final int size;

  /// MIME — `image/*` 면 사진 썸네일, 그 밖은 파일 카드. 비어 있으면 이름의 확장자로 가른다.
  final String type;

  /// 사진 썸네일 — 새로 고른 사진은 시스템 고르기가 만든다(FileImage).
  final ImageProvider? preview;

  /// 로컬 경로 — 올릴 때 쓰는 쪽이 읽는다.
  final String? path;
  final PAttachmentStatus status;

  /// 올리는 중 원 — 0 ~ 1. 없으면 값 없는 원(돈다).
  final double? progress;

  bool get isImage => attachmentIsImage(type, name);

  PAttachmentEntry copyWith({
    PAttachmentStatus? status,
    double? progress,
    bool clearProgress = false,
  }) => PAttachmentEntry(
    id: id,
    name: name,
    size: size,
    type: type,
    preview: preview,
    path: path,
    status: status ?? this.status,
    progress: clearProgress ? null : progress ?? this.progress,
  );
}

/// 고르기 창이 돌려준 파일 — 아직 항목이 아니다(검사를 거친다).
@immutable
class PAttachmentPicked {
  const PAttachmentPicked({
    required this.name,
    required this.size,
    this.type = '',
    this.path,
    this.preview,
  });

  final String name;
  final int size;
  final String type;
  final String? path;
  final ImageProvider? preview;
}

/// 거절된 파일과 이유 — 한 번 고른 것 가운데 거절된 것을 모아 한 번에 넘긴다.
@immutable
class PAttachmentRejection {
  const PAttachmentRejection({required this.file, required this.codes});

  final PAttachmentPicked file;
  final List<PAttachmentRejectionCode> codes;
}

/// 고르기 — [source] 의 창을 열어 파일을 돌려준다(취소면 빈 목록). [limit] 은 고를 수 있는 남은 개수.
/// 기본은 시스템 고르기(p_attachment_system_picker.dart), 테스트 · 견본은 가짜를 넘긴다.
typedef PAttachmentPickFiles =
    Future<List<PAttachmentPicked>> Function(
      PAttachmentSource source,
      int limit,
    );

/// 파일 크기 글 — "512B" · "84KB" · "9.8MB"(MB · GB 는 소수 한 자리, 띄어 쓰지 않는다). 웹 formatFileSize 와 같다.
String formatFileSize(int bytes) {
  final b = bytes < 0 ? 0 : bytes;
  if (b < 1024) return '${b}B';
  if (b < 1024 * 1024) return '${(b / 1024).round().clamp(1, 1 << 30)}KB';
  if (b < 1024 * 1024 * 1024) {
    return '${(b / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
}

final RegExp _imageExt = RegExp(
  r'\.(jpe?g|png|gif|webp|bmp|svg|heic|heif|avif)$',
  caseSensitive: false,
);
final RegExp _sheetExt = RegExp(
  r'\.(csv|xlsx?|ods|numbers)$',
  caseSensitive: false,
);
final RegExp _sheetType = RegExp(
  r'(csv|spreadsheet|ms-excel)',
  caseSensitive: false,
);

bool attachmentIsImage(String type, String name) =>
    type.isNotEmpty ? type.startsWith('image/') : _imageExt.hasMatch(name);

bool attachmentIsPdf(String type, String name) =>
    type == 'application/pdf' || name.toLowerCase().endsWith('.pdf');

bool attachmentIsSheet(String type, String name) =>
    _sheetType.hasMatch(type) || _sheetExt.hasMatch(name);

List<String> _tokens(String? accept) => (accept ?? '')
    .split(',')
    .map((t) => t.trim().toLowerCase())
    .where((t) => t.isNotEmpty)
    .toList();

/// accept 를 다시 검사한다 — 고르기 창의 accept 는 편의일 뿐이다("모든 파일" 로 다른 형식을 고를 수 있다).
bool attachmentAccepts(PAttachmentPicked file, String? accept) {
  final tokens = _tokens(accept);
  if (tokens.isEmpty) return true;
  final name = file.name.toLowerCase();
  final type = file.type.toLowerCase();
  return tokens.any((t) {
    if (t.startsWith('.')) return name.endsWith(t);
    if (t.endsWith('/*')) {
      return type.startsWith(t.substring(0, t.length - 1)) ||
          (t == 'image/*' && type.isEmpty && _imageExt.hasMatch(name));
    }
    return type == t;
  });
}

/// 받는 형식에 사진이 있나 — 있으면 타일 아이콘이 image, 없으면 paperclip.
bool attachmentAcceptsImages(String? accept) {
  final tokens = _tokens(accept);
  if (tokens.isEmpty) return true;
  return tokens.any((t) => t.startsWith('image/') || _imageExt.hasMatch(t));
}

/// 받는 형식에 사진이 아닌 것(PDF · 표 …)이 있나 — 있으면 "파일 고르기" 줄이 있다.
bool attachmentAcceptsFiles(String? accept) {
  final tokens = _tokens(accept);
  if (tokens.isEmpty) return true;
  return tokens.any((t) => !(t.startsWith('image/') || _imageExt.hasMatch(t)));
}

/// 어느 길을 열 수 있나 — 받는 형식에 없는 줄은 뺀다. 사진을 받으면 사진 찍기 · 앨범, 사진이 아닌 것을 받으면 파일 고르기.
List<PAttachmentSource> attachmentSources(String? accept) => [
  if (attachmentAcceptsImages(accept)) ...[
    PAttachmentSource.camera,
    PAttachmentSource.gallery,
  ],
  if (attachmentAcceptsFiles(accept)) PAttachmentSource.files,
];

/// 형식 · 크기 · 개수 검사 — 통과한 파일은 앞에서부터 남은 자리([room])만큼, 넘친 파일은 tooManyFiles.
({List<PAttachmentPicked> accepted, List<PAttachmentRejection> rejections})
attachmentValidate(
  List<PAttachmentPicked> files, {
  required int room,
  String? accept,
  int? maxFileSize,
}) {
  final accepted = <PAttachmentPicked>[];
  final rejections = <PAttachmentRejection>[];
  for (final file in files) {
    final codes = <PAttachmentRejectionCode>[];
    if (!attachmentAccepts(file, accept)) {
      codes.add(PAttachmentRejectionCode.invalidType);
    }
    if (maxFileSize != null && file.size > maxFileSize) {
      codes.add(PAttachmentRejectionCode.fileTooLarge);
    }
    if (codes.isEmpty && accepted.length >= room) {
      codes.add(PAttachmentRejectionCode.tooManyFiles);
    }
    if (codes.isEmpty) {
      accepted.add(file);
    } else {
      rejections.add(PAttachmentRejection(file: file, codes: codes));
    }
  }
  return (accepted: accepted, rejections: rejections);
}

int _seq = 0;

/// 새 항목 id.
String newAttachmentId() =>
    'attachment-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_seq++}';

/// 진행이 멈춘 올리기는 실패로 본다 — 10초(웹 STALL_MS).
const Duration kAttachmentStall = Duration(seconds: 10);
