// 생성 파일(institution_colors.g.dart)이 스펙 JSON 과 같은지 본다 — scripts/sync_design.sh 가 만든 것을 손으로 고치거나
// sync 를 빠뜨리면 여기서 걸린다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/shared/ds/institution_colors/institution_colors.dart';
import 'package:porest_desk_app/shared/ds/institution_colors/institution_colors.g.dart';

void main() {
  test('생성된 기관 색 표는 스펙 JSON 의 data.entries 와 같다', () {
    final spec =
        jsonDecode(
              File(
                'test/fixtures/design_spec/institution-colors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final entries = (spec['data'] as Map)['entries'] as List;

    expect((kInstitutionColorsSpec['data'] as Map)['entries'], equals(entries));
    expect(PInstitutionColors.table.entries, hasLength(entries.length));
    expect(PInstitutionColors.find('신한은행'), isNotNull);
    expect(PInstitutionColors.find('NH'), isNull);
  });
}
