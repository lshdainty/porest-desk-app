import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/accordion.md 미러.
///
/// FAQ-style vertical disclosure — 외곽 wrapper 없이 item마다 border-bottom 만.
/// Trigger: `title-sm` 16/500, padding-Y 16. Content: `body-md` 15/400 +
/// `fgSecondary`, padding-bottom 16. Chevron 180° rotate (open).
///
/// type=single — `singleOpenValue` 한 번에 1개. type=multiple — `multipleOpenValues`
/// Set 다중.
class PAccordionItem {
  const PAccordionItem({
    required this.value,
    required this.title,
    required this.content,
    this.disabled = false,
  });

  final String value;
  final String title;
  final Widget content;
  final bool disabled;
}

/// type=single — 한 번에 1개만 open. [collapsible] 이 true면 같은 item 다시 클릭 시 close.
class PAccordion extends StatefulWidget {
  const PAccordion({
    super.key,
    required this.items,
    this.initialOpen,
    this.collapsible = true,
    this.onOpenChanged,
  });

  final List<PAccordionItem> items;
  final String? initialOpen;
  final bool collapsible;
  final ValueChanged<String?>? onOpenChanged;

  @override
  State<PAccordion> createState() => _PAccordionState();
}

class _PAccordionState extends State<PAccordion> {
  String? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
  }

  void _toggle(String value) {
    setState(() {
      if (_open == value) {
        _open = widget.collapsible ? null : value;
      } else {
        _open = value;
      }
    });
    widget.onOpenChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final it in widget.items)
          _AccordionRow(
            item: it,
            open: _open == it.value,
            onToggle: () => _toggle(it.value),
          ),
      ],
    );
  }
}

/// type=multiple — Set 으로 동시 다중 open.
class PAccordionMultiple extends StatefulWidget {
  const PAccordionMultiple({
    super.key,
    required this.items,
    this.initialOpenValues = const <String>{},
    this.onOpenChanged,
  });

  final List<PAccordionItem> items;
  final Set<String> initialOpenValues;
  final ValueChanged<Set<String>>? onOpenChanged;

  @override
  State<PAccordionMultiple> createState() => _PAccordionMultipleState();
}

class _PAccordionMultipleState extends State<PAccordionMultiple> {
  late Set<String> _open;

  @override
  void initState() {
    super.initState();
    _open = {...widget.initialOpenValues};
  }

  void _toggle(String value) {
    setState(() {
      _open.contains(value) ? _open.remove(value) : _open.add(value);
    });
    widget.onOpenChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final it in widget.items)
          _AccordionRow(
            item: it,
            open: _open.contains(it.value),
            onToggle: () => _toggle(it.value),
          ),
      ],
    );
  }
}

class _AccordionRow extends StatelessWidget {
  const _AccordionRow({
    required this.item,
    required this.open,
    required this.onToggle,
  });

  final PAccordionItem item;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = item.disabled;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: disabled ? 0.5 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: disabled ? null : onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.titleSm,
                            fontWeight: PFontWeight.medium,
                            color: t.fgPrimary,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        duration: PMotion.base,
                        curve: PMotion.standard,
                        turns: open ? 0.5 : 0,
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: t.fgSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: PMotion.base,
            sizeCurve: PMotion.standard,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: PFontSize.bodyMd,
                  fontWeight: PFontWeight.regular,
                  height: PLineHeight.normal,
                  color: t.fgSecondary,
                ),
                child: item.content,
              ),
            ),
            crossFadeState: open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}
