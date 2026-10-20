import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_input.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';

const int _mb = 1024 * 1024;

/// 사진 썸네일 — 색이 다른 그림을 그려 만든다. 흰 그림은 덮개 · 대표 띠의 글이 읽히는지 본다(가장 나쁜 값).
const List<Color> _photoColors = [
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFFFFFFFF),
  Color(0xFF8B5CF6),
];

Future<List<ImageProvider>> _makePhotos() async {
  final out = <ImageProvider>[];
  for (final color in _photoColors) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 160, 160),
      Paint()..color = color,
    );
    canvas.drawCircle(
      const Offset(110, 50),
      22,
      Paint()..color = const Color(0xB3FFFFFF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 160)
        ..lineTo(60, 80)
        ..lineTo(110, 130)
        ..lineTo(130, 110)
        ..lineTo(160, 150)
        ..lineTo(160, 160)
        ..close(),
      Paint()..color = const Color(0x40000000),
    );
    final image = await recorder.endRecording().toImage(160, 160);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes != null) out.add(MemoryImage(bytes.buffer.asUint8List()));
  }
  return out;
}

/// 카탈로그(/dev/ds) — 항목(사진 · 파일 카드 × 고른 직후 · 올리는 중 · 올림 · 실패) · 첨부 타일(0 · 3 · 가득 참 · 최대 없음) · 대표 ·
/// 항목 메뉴 · 직접 해 보기(영수증 — 고르기 · 올리는 중 · 실패 · 거절 글) · 파일 하나(드롭존 대신 파일 선택 버튼) · 10/10 한 줄 ·
/// 읽기 전용 · 막힘. 누름 · 키보드 초점은 직접 해 본다. 고르기는 가짜다 — 기기의 카메라 · 앨범을 열지 않는다.
class AttachmentInputDemo extends StatefulWidget {
  const AttachmentInputDemo({super.key});

  @override
  State<AttachmentInputDemo> createState() => _AttachmentInputDemoState();
}

class _AttachmentInputDemoState extends State<AttachmentInputDemo> {
  List<ImageProvider> _photos = const [];
  int _seq = 0;

  // 견본 항목들
  late List<PAttachmentEntry> _states;
  late List<PAttachmentEntry> _cover;
  late List<PAttachmentEntry> _ten;
  late List<PAttachmentEntry> _threeOfTen;
  List<PAttachmentEntry> _receipt = [];
  List<PAttachmentEntry> _import = [];
  String? _receiptError;
  String? _importError;
  int _previewed = 0;
  int _pickCycle = 0;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _build();
    unawaited(
      _makePhotos().then((photos) {
        if (!mounted) return;
        setState(() {
          _photos = photos;
          _build();
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  ImageProvider? _photo(int i) =>
      _photos.isEmpty ? null : _photos[i % _photos.length];

  PAttachmentEntry _make(
    bool image,
    PAttachmentStatus status, {
    double? progress,
    String? name,
    int? size,
  }) {
    _seq++;
    return PAttachmentEntry(
      id: 'demo-$_seq',
      name: name ?? (image ? '영수증_$_seq.jpg' : '카드명세서_$_seq.pdf'),
      size: size ?? (image ? (2.4 * _mb).round() : (9.8 * _mb).round()),
      type: image ? 'image/jpeg' : 'application/pdf',
      preview: image ? _photo(_seq) : null,
      status: status,
      progress: progress,
    );
  }

  void _build() {
    _seq = 0;
    _states = [
      _make(true, PAttachmentStatus.pending),
      _make(false, PAttachmentStatus.pending),
      _make(true, PAttachmentStatus.uploading, progress: 0.4),
      _make(false, PAttachmentStatus.uploading, progress: 0.4),
      _make(true, PAttachmentStatus.success),
      _make(false, PAttachmentStatus.success),
      _make(true, PAttachmentStatus.error),
      _make(false, PAttachmentStatus.error),
    ];
    _cover = [
      for (var i = 0; i < 4; i++) _make(true, PAttachmentStatus.success),
    ];
    _threeOfTen = [
      _make(true, PAttachmentStatus.success),
      _make(false, PAttachmentStatus.success),
      _make(true, PAttachmentStatus.success),
    ];
    _ten = [
      for (var i = 0; i < 7; i++) _make(i.isEven, PAttachmentStatus.success),
      _make(true, PAttachmentStatus.uploading, progress: 0.6),
      _make(false, PAttachmentStatus.uploading, progress: 0.2),
      _make(true, PAttachmentStatus.error),
    ];
  }

  // ── 가짜 고르기 — 가장 나쁜 값을 돌려 가며 보낸다 ──────────────
  Future<List<PAttachmentPicked>> _fakePick(
    PAttachmentSource source,
    int limit,
  ) async {
    _pickCycle++;
    switch (source) {
      case PAttachmentSource.camera:
        return [
          PAttachmentPicked(
            name: 'IMG_${1000 + _pickCycle}.jpg',
            size: (3.1 * _mb).round(),
            type: 'image/jpeg',
            preview: _photo(_pickCycle),
          ),
        ];
      case PAttachmentSource.gallery:
        return [
          for (var i = 0; i < 3; i++)
            PAttachmentPicked(
              name: i == 2 ? '너무_큰_사진.jpg' : '앨범_${_pickCycle}_$i.jpg',
              size: i == 2 ? 12 * _mb : (1.8 * _mb).round(),
              type: 'image/jpeg',
              preview: _photo(_pickCycle + i),
            ),
        ];
      case PAttachmentSource.files:
        return const [
          PAttachmentPicked(
            name: '2026년_9월_카드_이용대금_명세서_최종_수정본_v3(사본).pdf',
            size: 9 * _mb + 800 * 1024,
            type: 'application/pdf',
          ),
          PAttachmentPicked(name: '메모.txt', size: 3 * 1024, type: 'text/plain'),
        ];
    }
  }

  void _upload(
    List<PAttachmentEntry> list,
    PAttachmentEntry entry,
    void Function(List<PAttachmentEntry>) put,
  ) {
    final id = entry.id;
    final fail = id.hashCode % 3 == 0;
    var step = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      step++;
      if (!mounted) return t.cancel();
      setState(() {
        final cur = _lookup(id);
        if (cur == null) return t.cancel();
        if (fail && step == 3) {
          put(_replace(cur, id, cur.copyWith(status: PAttachmentStatus.error)));
          t.cancel();
        } else if (step >= 5) {
          put(
            _replace(
              cur,
              id,
              cur.copyWith(status: PAttachmentStatus.success, progress: 1),
            ),
          );
          t.cancel();
        } else {
          put(
            _replace(
              cur,
              id,
              cur.copyWith(
                status: PAttachmentStatus.uploading,
                progress: step / 5,
              ),
            ),
          );
        }
      });
    });
    _timers.add(timer);
  }

  PAttachmentEntry? _lookup(String id) {
    for (final e in [..._receipt, ..._import]) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<PAttachmentEntry> _replace(
    PAttachmentEntry _,
    String id,
    PAttachmentEntry next,
  ) {
    final inReceipt = _receipt.any((e) => e.id == id);
    final source = inReceipt ? _receipt : _import;
    return [for (final e in source) e.id == id ? next : e];
  }

  static const _reject = {
    PAttachmentRejectionCode.fileTooLarge: '5MB 넘는 파일은 올릴 수 없어요.',
    PAttachmentRejectionCode.invalidType: '사진 · PDF 만 올릴 수 있어요.',
    PAttachmentRejectionCode.tooManyFiles: '20개까지 올릴 수 있어요.',
  };

  String _rejectText(List<PAttachmentRejection> list) =>
      list.map((r) => _reject[r.codes.first]!).toSet().join(' ');

  @override
  Widget build(BuildContext context) {
    void noRemove(String _) {}
    void noAccept(List<PAttachmentEntry> _) {}
    PAttachmentInput sample({
      required List<PAttachmentEntry> entries,
      int maxFiles = 10,
      String? accept = 'image/*,application/pdf',
      bool? disabled,
      bool? readOnly,
      String? badge,
      String label = '영수증',
    }) => PAttachmentInput(
      entries: entries,
      maxFiles: maxFiles,
      accept: accept,
      disabled: disabled,
      readOnly: readOnly,
      badgeLabel: badge,
      semanticLabel: label,
      pickFiles: _fakePick,
      onFilesAccept: noAccept,
      onRemove: noRemove,
      onPreview: readOnly == true ? (_) => setState(() => _previewed++) : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '항목 — 사진 80 · 파일 카드 160 × 80, 고른 직후 · 올리는 중(값 있는 원 24) · 올림 · 실패(덮개 + 다시 시도). 사진은 흰 그림도 있다',
          children: [
            for (var i = 0; i < _states.length; i += 2)
              DemoRow(
                label: const [
                  '고른 직후 · 올림은 같은 모습',
                  '올리는 중 40%',
                  '올림',
                  '실패',
                ][i ~/ 2],
                children: [
                  PAttachmentInput(
                    entries: _states.sublist(i, i + 2),
                    maxFiles: 10,
                    semanticLabel: '영수증',
                    pickFiles: _fakePick,
                    onFilesAccept: noAccept,
                    onRemove: noRemove,
                    onRetry: (_) {},
                  ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title:
              '첨부 타일 — 0/10 · 3/10 · 가득 참(막힌 모습, 초점은 남는다) · 최대 없음(개수 없음). 누르면 메뉴 시트',
          children: [
            DemoRow(
              label: '0/10',
              children: [sample(entries: const [])],
            ),
            DemoRow(
              label: '3/10',
              children: [sample(entries: _threeOfTen)],
            ),
            DemoRow(
              label: '최대 없음 · 파일만 받으면 paperclip',
              children: [
                sample(
                  entries: const [],
                  maxFiles: PAttachmentInput.unlimited,
                  accept: '.csv,.xlsx',
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '대표 · 순서 바꾸기 — 항목을 누르면 메뉴 시트(머리 = 파일 이름). 첫 항목은 앞으로 · 대표로, 끝 항목은 뒤로가 막힌다',
          children: [
            PAttachmentInput(
              entries: _cover,
              maxFiles: 10,
              accept: 'image/*',
              badgeLabel: '대표',
              semanticLabel: '사진',
              pickFiles: _fakePick,
              onFilesAccept: (added) =>
                  setState(() => _cover = [..._cover, ...added]),
              onRemove: (id) => setState(
                () => _cover = _cover.where((e) => e.id != id).toList(),
              ),
              onReorder: (next) => setState(() => _cover = next),
              onPreview: (_) => setState(() => _previewed++),
            ),
            Text('크게 보기를 $_previewed번 눌렀어요'),
          ],
        ),
        DemoBlock(
          title:
              '직접 해 보기 — 영수증(고르기 · 올리는 중 · 실패 · 거절 글). 가장 나쁜 값: 긴 이름 · 5MB 넘는 파일 · 형식이 다른 파일 · 20개',
          children: [
            PField(
              label: '영수증',
              description: '사진 · PDF 를 5MB 까지 올려요. 20개까지.',
              invalid: _receiptError != null,
              errorMessage: _receiptError,
              child: PAttachmentInput(
                entries: _receipt,
                maxFiles: 20,
                maxFileSize: 5 * _mb,
                accept: 'image/*,application/pdf',
                pickFiles: _fakePick,
                onFilesAccept: (added) {
                  setState(() {
                    _receiptError = null;
                    _receipt = [..._receipt, ...added];
                  });
                  for (final e in added) {
                    _upload(_receipt, e, (next) => _receipt = next);
                  }
                },
                onFilesReject: (list) =>
                    setState(() => _receiptError = _rejectText(list)),
                onRemove: (id) => setState(
                  () => _receipt = _receipt.where((e) => e.id != id).toList(),
                ),
                onRetry: (id) {
                  final e = _receipt.firstWhere((x) => x.id == id);
                  setState(() {
                    _receipt = [
                      for (final x in _receipt)
                        x.id == id
                            ? x.copyWith(
                                status: PAttachmentStatus.uploading,
                                progress: 0.1,
                              )
                            : x,
                    ];
                  });
                  _upload(_receipt, e, (next) => _receipt = next);
                },
              ),
            ),
          ],
        ),
        DemoBlock(
          title:
              '파일 하나 가져오기 — 앱은 드롭존 없이 "파일 선택" 버튼(large · 칸 폭 · 앞 아이콘 upload) + 고른 파일 카드',
          children: [
            PField(
              label: '가져올 파일',
              description: 'CSV · Excel 파일을 10MB 까지 올려요.',
              invalid: _importError != null,
              errorMessage: _importError,
              child: PAttachmentInput(
                layout: PAttachmentLayout.dropzone,
                entries: _import,
                accept: '.csv,.xlsx,.xls',
                maxFileSize: 10 * _mb,
                pickFiles: (source, limit) async => const [
                  PAttachmentPicked(
                    name: '카드_거래내역_2026_09.xlsx',
                    size: 4 * _mb + 200 * 1024,
                    type:
                        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  ),
                ],
                onFilesAccept: (added) => setState(() {
                  _importError = null;
                  _import = added;
                }),
                onFilesReject: (list) => setState(
                  () => _importError = 'CSV · Excel 파일을 10MB 까지 올릴 수 있어요.',
                ),
                onRemove: (_) => setState(() => _import = []),
              ),
            ),
          ],
        ),
        DemoBlock(
          title:
              '10/10 한 줄(밀어서 본다 — 올리는 중 · 실패가 끝에 있다) · 읽기 전용(누르면 바로 크게 보기, 사진은 흐리다) · 막힘',
          children: [
            DemoRow(
              label: '10/10',
              children: [sample(entries: _ten)],
            ),
            DemoRow(
              label: '읽기 전용',
              children: [
                sample(entries: _states.sublist(0, 4), readOnly: true),
              ],
            ),
            DemoRow(
              label: '막힘',
              children: [
                sample(entries: _states.sublist(0, 4), disabled: true),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
