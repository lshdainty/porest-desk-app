import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/quantity_picker/p_quantity_picker.dart';

String _times(int v) => '$v회';
String _hours(int v) => '${v}h';

/// 카탈로그(/dev/ds) — 앱은 large 52 만. 끝(최소 · 최대) · 지우기 · 폭(fill · hug) · Field 안(기본 · 읽기 전용 · 범위 밖 오류 · 막힘) ·
/// 로딩 · 가장 나쁜 값(아주 큰 수 · 0 · 긴 단위 · step). 누름 · 키보드 초점은 직접 해 본다.
class QuantityPickerDemo extends StatefulWidget {
  const QuantityPickerDemo({super.key});

  @override
  State<QuantityPickerDemo> createState() => _QuantityPickerDemoState();
}

class _QuantityPickerDemoState extends State<QuantityPickerDemo> {
  int _approvals = 2;
  int _big = 123456789;
  int _lunch = 2;
  bool _lunchRemoved = false;
  int _loadingValue = 1;
  PQuantityLoading _loading = PQuantityLoading.none;
  int _step = 15;

  Future<void> _server(bool decrement, int next) async {
    setState(
      () => _loading = decrement
          ? PQuantityLoading.decrement
          : PQuantityLoading.increment,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _loadingValue = next;
      _loading = PQuantityLoading.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '기본 — large 52 · 값 2(0 ~ 3). 길게 눌러도 한 단계, 값 칸은 누르지 못한다',
          children: [
            PQuantityPicker(
              semanticLabel: '승인 필요 횟수',
              value: _approvals,
              max: 3,
              getValueText: _times,
              onValueChange: (v) => setState(() => _approvals = v),
            ),
          ],
        ),
        const DemoBlock(
          title: '끝 — 최소 0 은 줄이기, 최대 3 은 늘리기가 막힌 모습(눌러도 바탕 · 축소 없음)',
          children: [
            DemoRow(
              label: '최소 0',
              children: [
                PQuantityPicker(
                  semanticLabel: '최소',
                  defaultValue: 0,
                  max: 3,
                  getValueText: _times,
                ),
              ],
            ),
            DemoRow(
              label: '최대 3',
              children: [
                PQuantityPicker(
                  semanticLabel: '최대',
                  defaultValue: 3,
                  max: 3,
                  getValueText: _times,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: "지우기(removable) — 최소에서 줄이기 자리가 휴지통 · 이름 '점심 도시락 지우기'. 막히지 않는다",
          children: [
            if (_lunchRemoved)
              const Text('지웠어요(다시 보려면 화면을 다시 열어요)')
            else
              PQuantityPicker(
                semanticLabel: '점심 도시락',
                value: _lunch,
                min: 1,
                max: 9,
                getValueText: (v) => '$v개',
                removable: true,
                removeSemanticLabel: '점심 도시락 지우기',
                onRemove: () => setState(() => _lunchRemoved = true),
                onValueChange: (v) => setState(() => _lunch = v),
              ),
          ],
        ),
        DemoBlock(
          title:
              '폭 — fill 은 남은 폭(늘어나는 것은 값 칸뿐), hug 는 가장 긴 값(min · max · 지금)의 폭',
          children: [
            const DemoRow(
              label: 'fill',
              children: [
                SizedBox(
                  width: 342,
                  child: PQuantityPicker(
                    semanticLabel: '승인 필요 횟수',
                    layout: PQuantityLayout.fill,
                    defaultValue: 2,
                    max: 3,
                    getValueText: _times,
                  ),
                ),
              ],
            ),
            const DemoRow(
              label: 'hug · 최대 99회',
              children: [
                PQuantityPicker(
                  semanticLabel: '횟수',
                  defaultValue: 5,
                  max: 99,
                  getValueText: _times,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              'Field 안 — 라벨이 묶음의 이름, 설명 · 오류가 묶음의 설명. Field 의 막힘 · 읽기 전용 · 오류를 받는다',
          children: [
            PField(
              label: '승인 필요 횟수',
              description: '0 이면 승인 없이 바로 써요.',
              child: PQuantityPicker(
                value: _approvals,
                max: 3,
                getValueText: _times,
                onValueChange: (v) => setState(() => _approvals = v),
              ),
            ),
            const PField(
              label: '읽기 전용',
              readOnly: true,
              child: PQuantityPicker(
                defaultValue: 2,
                max: 3,
                getValueText: _times,
              ),
            ),
            const PField(
              label: '범위 밖(오류)',
              invalid: true,
              errorMessage: '최대 3회까지 정할 수 있어요.',
              child: PQuantityPicker(value: 5, max: 3, getValueText: _times),
            ),
            const PField(
              label: '막힘',
              disabled: true,
              child: PQuantityPicker(
                defaultValue: 2,
                max: 3,
                getValueText: _times,
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '서버에 바로 반영 — 누른 쪽 버튼만 기다린다(1.2초)',
          children: [
            PQuantityPicker(
              semanticLabel: '좌석 수',
              value: _loadingValue,
              max: 9,
              loading: _loading,
              getValueText: (v) => '$v석',
              onValueChange: (v) => _server(v < _loadingValue, v),
            ),
          ],
        ),
        DemoBlock(
          title: '가장 나쁜 값 — 아주 큰 수(max 없음) · 0 · 긴 단위 · 간격(step)',
          children: [
            PQuantityPicker(
              semanticLabel: '큰 수',
              value: _big,
              onValueChange: (v) => setState(() => _big = v),
            ),
            const PQuantityPicker(
              semanticLabel: '승인자',
              defaultValue: 0,
              max: 3,
              getValueText: _approverText,
            ),
            PQuantityPicker(
              semanticLabel: '분',
              value: _step,
              step: 5,
              max: 60,
              getValueText: (v) => '$v분',
              onValueChange: (v) => setState(() => _step = v),
            ),
            const PQuantityPicker(
              semanticLabel: '부여 시간',
              defaultValue: 4,
              max: 7,
              getValueText: _hours,
            ),
          ],
        ),
      ],
    );
  }
}

String _approverText(int v) => '$v명의 승인자';
