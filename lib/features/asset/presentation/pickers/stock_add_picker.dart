import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/features/asset/presentation/pickers/picker_sheet.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';

/// 종목 추가 시트가 돌려주는 것 — 검색에서 찾은 종목([found]) 또는 검색어 그대로 직접 추가([manualName]).
class StockPick {
  const StockPick.found(StockMasterItem this.found) : manualName = null;
  const StockPick.manual(String this.manualName) : found = null;

  final StockMasterItem? found;
  final String? manualName;
}

const _manual = '__manual__';

/// 종목 추가(I-17 20) — "종목 추가" 단추가 여는 검색 시트. 서버 검색은 마지막 입력 뒤 300ms 에 한 번.
///
/// 줄은 "고르면 그 종목을 더한다"(오른쪽 라디오는 Searchable List 줄의 모양 그대로). 이미 담은 연동 종목은 목록에서 빼고, 검색어가 있으면 맨 아래에
/// "직접 추가 — 평가액 입력" 줄이 선다. 고르면 시트가 닫히고 [StockPick] 이 돌아온다(취소하면 null).
Future<StockPick?> showStockAddPicker(
  BuildContext context, {
  required Set<String> excludeSymbols,
}) {
  final focus = FocusNode(debugLabel: 'stock search');
  return PBottomSheet.show<StockPick>(
    context,
    initialFocus: focus,
    builder: (_) =>
        StockAddSheet(excludeSymbols: excludeSymbols, searchFocus: focus),
  ).whenComplete(focus.dispose);
}

class StockAddSheet extends ConsumerStatefulWidget {
  const StockAddSheet({
    super.key,
    required this.excludeSymbols,
    required this.searchFocus,
  });

  final Set<String> excludeSymbols;
  final FocusNode searchFocus;

  @override
  ConsumerState<StockAddSheet> createState() => _StockAddSheetState();
}

class _StockAddSheetState extends ConsumerState<StockAddSheet> {
  /// 친 대로의 검색어(직접 추가 줄에 쓴다)와 서버로 보낸 검색어(300ms 뒤).
  String _typed = '';
  String _sent = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = _typed.trim();
    final async = ref.watch(stockSearchProvider(_sent));
    final results = [
      for (final s in async.value ?? const <StockMasterItem>[])
        if (!widget.excludeSymbols.contains(s.symbol)) s,
    ].take(6).toList();
    final fetching = async.isLoading && results.isEmpty;

    // 검색어가 없으면 줄이 없다. 0건 안내가 먼저, 직접 추가 줄은 늘 맨 아래(I-17 20)
    Widget? body;
    if (query.isNotEmpty) {
      body = fetching
          ? const PSearchableListSkeleton(rows: 3)
          : PSearchableListResults(
              semanticLabel: l.assetHoldings,
              children: [
                for (final s in results)
                  PSearchableListItem(
                    value: '${s.marketCode}:${s.symbol}',
                    title: s.nameKr,
                    detail: '${s.symbol} · ${s.marketCode}',
                  ),
                PSearchableListItem(
                  value: _manual,
                  title: l.assetHoldingAddManual(query),
                  prefix: const Icon(LucideIcons.plus, size: 20),
                ),
              ],
            );
    }

    return PBottomSheetContent(
      title: l.assetAddStock,
      closeLabel: l.actionClose,
      flushBody: true,
      body: SizedBox(
        height: pickerBodyHeight(context),
        child: PSearchableList(
          focusNode: widget.searchFocus,
          query: _typed,
          onQueryChanged: (q) => setState(() => _typed = q),
          onSearch: (q) => setState(() => _sent = q),
          onValueChanged: (v) {
            if (v == _manual) {
              PBottomSheet.of(context).close(StockPick.manual(query));
              return;
            }
            final s = results
                .where((r) => '${r.marketCode}:${r.symbol}' == v)
                .firstOrNull;
            if (s != null) PBottomSheet.of(context).close(StockPick.found(s));
          },
          children: [
            PSearchableListInput(
              placeholder: l.assetHoldingSearchHint,
              semanticLabel: l.actionSearch,
            ),
            if (query.isNotEmpty && results.isEmpty && !fetching)
              PSearchableListEmpty(titleBuilder: (q) => l.assetSearchEmpty(q)),
            ?body,
          ],
        ),
      ),
    );
  }
}
