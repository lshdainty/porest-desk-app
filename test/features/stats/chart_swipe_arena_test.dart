// fl_chart 가 올라간 PageView 에서 가로 스와이프가 페이지를 넘기는지 확인한다.
//
// fl_chart 는 touchCallback 이 있으면 PanGestureRecognizer 를 아레나에 넣는다
// (render_base_chart.dart handleEvent). PageView 는 HorizontalDragGestureRecognizer 다.
// 둘이 경합하면 슬롭이 작은 쪽(가로 드래그 18 < 팬 36)이 먼저 승리를 선언한다 —
// 이론상 PageView 가 이기지만, 통계 화면 탭 스와이프가 차트 위에서 죽는지는
// 돌려봐야 안다. 이 테스트가 그 근거다.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('차트 위에서 가로로 밀어도 PageView 가 페이지를 넘긴다', (tester) async {
    final controller = PageController();
    var chartTouched = false;

    Widget chartPage(Color c) => Center(
          child: SizedBox(
            width: 300,
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) => chartTouched = true,
                ),
                lineBarsData: [
                  LineChartBarData(spots: const [
                    FlSpot(0, 1),
                    FlSpot(1, 3),
                    FlSpot(2, 2),
                  ], color: c),
                ],
              ),
            ),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PageView(
          controller: controller,
          children: [chartPage(Colors.red), chartPage(Colors.blue)],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(controller.page, 0);

    // 차트 한가운데에서 왼쪽으로 밀어 다음 페이지로.
    await tester.fling(find.byType(LineChart).first, const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();

    expect(controller.page, 1,
        reason: '차트가 pan 을 가로채면 여기서 0 으로 남는다 — 스와이프 데드존이라는 뜻');
    // 참고용 — 차트가 터치 이벤트를 받았는지는 승패와 별개다.
    debugPrint('chart touchCallback fired: $chartTouched');
  });
}
