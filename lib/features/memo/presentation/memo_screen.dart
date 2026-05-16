import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/memo_providers.dart';
import '../domain/memo.dart';
import 'memo_edit_dialog.dart';
import 'memo_folder_management_dialog.dart';

class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key});
  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasQuery = _query.trim().isNotEmpty;
    final searchAsync = ref.watch(memoSearchProvider(
        (folderId: null, search: hasQuery ? _query.trim() : null)));
    final listAsync = hasQuery ? searchAsync : ref.watch(memoListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('메모'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton.icon(
            icon: LucideIcons.folderTree,
            tooltip: '폴더 관리',
            onPressed: () => showMemoFolderManagementDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, 0, PSpace.x16, PSpace.x12),
            child: PTextInput(
              controller: _searchCtrl,
              placeholder: '메모 검색',
              prefix:
                  Icon(LucideIcons.search, size: 16, color: t.fgTertiary),
              suffix: hasQuery
                  ? IconButton(
                      icon: Icon(LucideIcons.x,
                          size: 16, color: t.fgTertiary),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        onPressed: () => showMemoEditDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          if (hasQuery) {
            ref.invalidate(memoSearchProvider(
                (folderId: null, search: _query.trim())));
          } else {
            ref.invalidate(memoListProvider);
          }
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('메모 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: [
                PEmptyState(
                  icon: LucideIcons.fileText,
                  message: hasQuery ? '검색 결과가 없습니다' : '등록된 메모가 없습니다',
                ),
              ]);
            }
            // pinned 먼저
            final sorted = [...items]..sort((a, b) {
                if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
                return (b.modifyAt ?? '').compareTo(a.modifyAt ?? '');
              });
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
              itemBuilder: (_, i) => _MemoCard(
                memo: sorted[i],
                tokens: t,
                onTap: () => showMemoEditDialog(context, edit: sorted[i]),
                onPin: () async {
                  try {
                    final repo = await ref.read(memoRepositoryProvider.future);
                    await repo.pin(sorted[i].rowId);
                    ref.invalidate(memoListProvider);
                    if (hasQuery) {
                      ref.invalidate(memoSearchProvider(
                          (folderId: null, search: _query.trim())));
                    }
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.memo,
    required this.tokens,
    required this.onTap,
    required this.onPin,
  });
  final Memo memo;
  final PorestTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onPin;
  @override
  Widget build(BuildContext context) {
    final hasTitle = (memo.title ?? '').isNotEmpty;
    final preview = (memo.content ?? '').replaceAll('\n', ' ');

    return Material(
      color: tokens.bgSurface,
      borderRadius: PRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: PRadius.brLg,
        child: Container(
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            borderRadius: PRadius.brLg,
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTitle ? memo.title! : '(제목 없음)',
                      style: PTypo.body.copyWith(
                          color: hasTitle
                              ? tokens.fgPrimary
                              : tokens.fgTertiary,
                          fontWeight: PFontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(preview,
                          style: PTypo.caption
                              .copyWith(color: tokens.fgTertiary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              PButton.icon(
                icon: LucideIcons.pin,
                size: PButtonSize.sm,
                iconColor:
                    memo.pinned ? tokens.fgBrand : tokens.fgTertiary,
                tooltip: memo.pinned ? '고정 해제' : '고정',
                onPressed: onPin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
