import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/catalog/ds_registry.dart';

/// 컴포넌트 라이브러리 카탈로그 — debug 빌드 전용(/dev/ds). 운영 빌드에는 들어가지 않는다
/// (`app/router.dart` 가 kDebugMode 일 때만 길을 둔다).
///
/// 먼저 다 만들고 화면은 나중에 옮기므로(2026-10-06 결정), 새 컴포넌트를 쓰는 화면이 아직 없다.
/// 만든 것을 볼 자리가 여기다 — 스펙의 변형 · 크기 · 상태를 라이트 · 다크 판에 위아래로 그린다.
/// 판마다 그 아래만 그 모드의 테마로 감싼다 — `context.colors` 가 그 모드의 역할 색을 준다.
/// 개발 도구라 글은 l10n 을 거치지 않는다.
class DsCatalogScreen extends StatelessWidget {
  const DsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = dsFamilies.expand((f) => f.entries).toList();
    final built = entries.where((e) => e.demo != null).length;

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: AppBar(
        title: const Text('Desk 컴포넌트 라이브러리'),
        backgroundColor: c.bgLayerBasement,
        foregroundColor: c.fgNeutral,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.x4,
          PSpacing.x2,
          PSpacing.x4,
          PSpacing.x12,
        ),
        children: [
          Text(
            '개발 전용 — 운영 빌드에는 들어가지 않는다',
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
          const SizedBox(height: PSpacing.x1_5),
          Text(
            '확정 스펙 ${entries.length}개 중 $built개를 만들었다 · 스펙 값 '
            '${PDesignSource.file} · ${PDesignSource.sha256} '
            '(scripts/sync_design.sh)',
            style: PTypography.t4.copyWith(color: c.fgNeutralMuted),
          ),
          const SizedBox(height: PSpacing.x8),
          const _Section(
            title: '역할 색',
            child: _ModePanels(child: _RoleSwatches()),
          ),
          for (final family in dsFamilies)
            _Section(
              title: family.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in family.entries) _EntryView(entry: entry),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpacing.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: PTypography.t7.copyWith(
              color: context.colors.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PSpacing.x4),
          child,
        ],
      ),
    );
  }
}

class _EntryView extends StatelessWidget {
  const _EntryView({required this.entry});

  final DsEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final demo = entry.demo;
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry.name,
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          if (demo != null)
            _ModePanels(child: Builder(builder: demo))
          else
            Text(
              '아직 만들지 않았다 — 스펙 specs/components/${entry.spec}.md',
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
        ],
      ),
    );
  }
}

/// 라이트 · 다크 판 — 같은 내용을 두 모드로. 폰 폭이라 위아래로 놓는다.
class _ModePanels extends StatelessWidget {
  const _ModePanels({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModePanel(label: '라이트', theme: PorestTheme.light(), child: child),
        const SizedBox(height: PSpacing.x3),
        _ModePanel(label: '다크', theme: PorestTheme.dark(), child: child),
      ],
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({
    required this.label,
    required this.theme,
    required this.child,
  });

  final String label;
  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final c = context.colors;
          return Container(
            padding: const EdgeInsets.all(PSpacing.x5),
            decoration: BoxDecoration(
              color: c.bgLayerDefault,
              border: Border.all(color: c.strokeNeutralSubtle),
              borderRadius: BorderRadius.circular(PRounded.r3),
            ),
            child: DefaultTextStyle.merge(
              style: PTypography.t4.copyWith(color: c.fgNeutral),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    label,
                    style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
                  ),
                  const SizedBox(height: PSpacing.x3),
                  child,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleSwatches extends StatelessWidget {
  const _RoleSwatches();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in dsRoleSwatches) ...[
          Text(
            group.group,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PSpacing.x2),
          Wrap(
            spacing: PSpacing.x3,
            runSpacing: PSpacing.x2,
            children: [
              for (final s in group.swatches)
                SizedBox(
                  width: 140,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: s.of(c),
                          border: Border.all(color: c.strokeNeutralWeak),
                          borderRadius: BorderRadius.circular(PRounded.r1_5),
                        ),
                      ),
                      const SizedBox(width: PSpacing.x2),
                      Expanded(
                        child: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: PTypography.t2.copyWith(
                            color: c.fgNeutralMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: PSpacing.x4),
        ],
      ],
    );
  }
}
