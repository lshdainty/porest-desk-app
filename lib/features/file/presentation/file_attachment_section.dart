import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/features/file/application/file_providers.dart';
import 'package:porest_desk_app/features/file/domain/file_attachment.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

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
      showPSnackBar(context, '$name 업로드 완료', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '업로드 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FileAttachment f) async {
    final ok = await showPConfirmDialog(
      context,
      title: '파일 삭제',
      message: '${f.originalName} 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(fileRepositoryProvider.future);
      await repo.delete(f.rowId);
      ref.invalidate(filesByReferenceProvider(_key));
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
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
                    color: t.fgPrimary, fontWeight: PFontWeight.bold)),
            const Spacer(),
            PButton.icon(
              icon: LucideIcons.image,
              size: PButtonSize.sm,
              tooltip: '갤러리',
              onPressed: _busy ? null : _pickImage,
            ),
            PButton.icon(
              icon: LucideIcons.camera,
              size: PButtonSize.sm,
              tooltip: '카메라',
              onPressed: _busy ? null : _pickCamera,
            ),
            PButton.icon(
              icon: LucideIcons.file,
              size: PButtonSize.sm,
              tooltip: '파일',
              onPressed: _busy ? null : _pickFile,
            ),
          ],
        ),
        const SizedBox(height: 6),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: PCircularProgressIndicator()),
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
                                      fontWeight: PFontWeight.semi)),
                              if ((f.fileSize ?? 0) > 0)
                                Text(_humanSize(f.fileSize),
                                    style: PTypo.micro.copyWith(
                                        color: t.fgTertiary)),
                            ],
                          ),
                        ),
                        PButton.icon(
                          icon: LucideIcons.x,
                          size: PButtonSize.sm,
                          iconColor: t.fgTertiary,
                          onPressed: _busy ? null : () => _delete(f),
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
