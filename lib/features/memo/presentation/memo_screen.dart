import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../application/memo_providers.dart';
import '../domain/memo.dart';
import 'memo_edit_dialog.dart';

class MemoScreen extends ConsumerWidget {
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final listAsync = ref.watch(memoListProvider);

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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => showMemoEditDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(memoListProvider);
          await ref.read(memoListProvider.future);
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
                Padding(
                  padding: const EdgeInsets.all(PSpace.x32),
                  child: Column(
                    children: [
                      Icon(LucideIcons.fileText,
                          size: 48, color: t.fgDisabled),
                      const SizedBox(height: PSpace.x12),
                      Text('등록된 메모가 없습니다',
                          style: PTypo.body.copyWith(color: t.fgTertiary)),
                    ],
                  ),
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
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('실패: ${e.message}')),
                    );
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
                          fontWeight: FontWeight.w700),
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
              IconButton(
                onPressed: onPin,
                icon: Icon(
                  memo.pinned ? LucideIcons.pin : LucideIcons.pin,
                  size: 16,
                  color: memo.pinned
                      ? tokens.fgBrand
                      : tokens.fgTertiary,
                ),
                tooltip: memo.pinned ? '고정 해제' : '고정',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
