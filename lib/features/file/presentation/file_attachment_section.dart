import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../application/file_providers.dart';
import '../domain/file_attachment.dart';

/// 첨부 파일 섹션 — 거래/할일/메모/이벤트 상세에 embed.
///
/// `referenceType` 은 백엔드 enum: EXPENSE/TODO/MEMO/CALENDAR_EVENT.
/// `referenceRowId` 는 해당 entity 의 rowId. (entity 신규 생성 직후 호출 권장)
class FileAttachmentSection extends ConsumerStatefulWidget {
  const FileAttachmentSection({
    super.key,
    required this.referenceType,
    required this.referenceRowId,
  });

  final String referenceType;
  final int referenceRowId;

  @override
  ConsumerState<FileAttachmentSection> createState() =>
      _FileAttachmentSectionState();
}

class _FileAttachmentSectionState
    extends ConsumerState<FileAttachmentSection> {
  bool _busy = false;

  FileRefKey get _key => (
        referenceType: widget.referenceType,
        referenceRowId: widget.referenceRowId,
      );

  Future<void> _pickImage() async {
    if (_busy) return;
    final pickr = ImagePicker();
    final picked = await pickr.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _upload(picked.path, picked.name);
  }

  Future<void> _pickCamera() async {
    if (_busy) return;
    final pickr = ImagePicker();
    final picked = await pickr.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    await _upload(picked.path, picked.name);
  }

  Future<void> _pickFile() async {
    if (_busy) return;
    final picked = await FilePicker.platform.pickFiles();
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    if (f.path == null) return;
    await _upload(f.path!, f.name);
  }

  Future<void> _upload(String path, String name) async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(fileRepositoryProvider.future);
      await repo.upload(
        filePath: path,
        fileName: name,
        referenceType: widget.referenceType,
        referenceRowId: widget.referenceRowId,
      );
      ref.invalidate(filesByReferenceProvider(_key));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name 업로드 완료')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FileAttachment f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('${f.originalName} 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(fileRepositoryProvider.future);
      await repo.delete(f.rowId);
      ref.invalidate(filesByReferenceProvider(_key));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanSize(int? size) {
    if (size == null) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final async = ref.watch(filesByReferenceProvider(_key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.paperclip, size: 14, color: t.fgSecondary),
            const SizedBox(width: 6),
            Text('첨부 파일',
                style: PTypo.caption.copyWith(
                    color: t.fgPrimary, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: Icon(LucideIcons.image, size: 16, color: t.fgSecondary),
              tooltip: '갤러리',
              onPressed: _busy ? null : _pickImage,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(LucideIcons.camera, size: 16, color: t.fgSecondary),
              tooltip: '카메라',
              onPressed: _busy ? null : _pickCamera,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(LucideIcons.file, size: 16, color: t.fgSecondary),
              tooltip: '파일',
              onPressed: _busy ? null : _pickFile,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('첨부 로드 실패',
              style: PTypo.caption.copyWith(color: t.statusDanger)),
          data: (files) {
            if (files.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('첨부된 파일 없음',
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary)),
              );
            }
            return Column(
              children: [
                for (final f in files)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: t.bgSurface,
                      borderRadius: PRadius.brSm,
                      border: Border.all(color: t.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            f.isImage
                                ? LucideIcons.image
                                : LucideIcons.fileText,
                            size: 14,
                            color: t.fgSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(f.originalName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PTypo.caption.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: FontWeight.w600)),
                              if ((f.fileSize ?? 0) > 0)
                                Text(_humanSize(f.fileSize),
                                    style: PTypo.micro.copyWith(
                                        color: t.fgTertiary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x,
                              size: 14, color: t.fgTertiary),
                          onPressed: _busy ? null : () => _delete(f),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
