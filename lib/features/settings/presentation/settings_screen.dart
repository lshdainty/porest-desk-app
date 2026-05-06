import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import 'appearance_section.dart';

/// 설정 화면 (push 라우트). v0.1 은 표시 설정 1개 섹션만.
/// Phase 후속에서 카테고리/계좌·카드/예산/반복/프리셋/알림/데이터/계정 섹션 추가.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('설정'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(PSpace.x20),
        children: [
          Text('표시 설정',
              style: PTypo.h3.copyWith(color: t.fgPrimary)),
          const SizedBox(height: PSpace.x4),
          Text('테마·밀도·통화',
              style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x20),
          const AppearanceSection(),
        ],
      ),
    );
  }
}
