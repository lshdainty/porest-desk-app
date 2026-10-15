import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:porest_desk_app/shared/ds/attachment_input/p_attachment_model.dart';

/// 시스템 고르기 — 사진 찍기(카메라) · 앨범에서 고르기(갤러리) · 파일 고르기. [PAttachmentPickFiles] 의 기본 구현이다.
///
/// 이미 앱이 쓰는 `image_picker` · `file_picker` 를 그대로 쓴다(새 의존성 없음). 취소하면 빈 목록이다.
/// 테스트 · 견본에서는 쓰지 않는다 — 플러그인은 기기에서만 돈다.
Future<List<PAttachmentPicked>> pickSystemAttachments(
  PAttachmentSource source,
  int limit,
) async {
  switch (source) {
    case PAttachmentSource.camera:
      final shot = await ImagePicker().pickImage(source: ImageSource.camera);
      return [if (shot != null) await _fromXFile(shot)];
    case PAttachmentSource.gallery:
      final picker = ImagePicker();
      final shots = limit > 1
          ? await picker.pickMultiImage(limit: limit)
          : [?await picker.pickImage(source: ImageSource.gallery)];
      return [for (final x in shots) await _fromXFile(x)];
    case PAttachmentSource.files:
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: limit > 1,
      );
      if (picked == null) return const [];
      return [
        for (final f in picked.files)
          PAttachmentPicked(
            name: f.name,
            size: f.size,
            path: f.path,
            type: _mimeOf(f.extension),
            preview: _isImageExt(f.extension) && f.path != null
                ? FileImage(File(f.path!))
                : null,
          ),
      ];
  }
}

Future<PAttachmentPicked> _fromXFile(XFile x) async => PAttachmentPicked(
  name: x.name,
  size: await x.length(),
  type: x.mimeType ?? _mimeOf(x.name.split('.').last),
  path: x.path,
  preview: FileImage(File(x.path)),
);

bool _isImageExt(String? ext) => const {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
}.contains(ext?.toLowerCase());

String _mimeOf(String? ext) => switch (ext?.toLowerCase()) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'gif' => 'image/gif',
  'webp' => 'image/webp',
  'bmp' => 'image/bmp',
  'heic' => 'image/heic',
  'heif' => 'image/heif',
  'pdf' => 'application/pdf',
  'csv' => 'text/csv',
  'xls' => 'application/vnd.ms-excel',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  _ => '',
};
