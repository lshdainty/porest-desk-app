/// groo_logo.svg · groo_icon.svg 의 나무 path 그대로(trunk · left-leaf · right-leaf · overlap).
/// 네이티브 벡터 drawable 의 pathData 와 대조한다.
const grooTreePaths = <String, String>{
  'trunk':
      'M212 282H235 C234 304 237 323 244 339 H203 C210 321 212 303 212 282Z',
  'left-leaf':
      'M163 193 C182 191 207 201 224 212 C245 230 248 261 224 288 C201 290 178 282 166 265 C154 248 154 215 163 193Z',
  'right-leaf':
      'M224 212 C242 201 265 194 284 193 C292 214 294 245 282 265 C271 282 248 290 224 288 C201 263 200 232 224 212Z',
  'overlap': 'M224 212 C245 230 248 261 224 288 C201 263 200 232 224 212Z',
};

/// 시안 칠(로고 결정 — 라이트 · 다크 같다).
const grooTreeFills = <String, String>{
  'trunk': '#A96D57',
  'left-leaf': '#075B3C',
  'right-leaf': '#43BF5E',
  'overlap': '#218D49',
};

/// 벡터 drawable 의 <path> 들을 (fillColor, pathData) 로 읽는다.
List<(String, String)> readVectorPaths(String xml) {
  final re = RegExp(
    r'android:fillColor="([^"]+)"\s+android:pathData="([^"]+)"',
  );
  return [for (final m in re.allMatches(xml)) (m.group(1)!, m.group(2)!)];
}

/// M · C · H · Z(절대 좌표)만 있는 path 의 모든 점(끝점 + 제어점).
List<(double, double)> pathPoints(String d) {
  final tok = RegExp(
    r'[MCHZ]|-?\d+(?:\.\d+)?',
  ).allMatches(d).map((m) => m[0]!).toList();
  final pts = <(double, double)>[];
  var i = 0;
  var cx = 0.0, cy = 0.0;
  String cmd = '';
  while (i < tok.length) {
    final t = tok[i];
    if (RegExp(r'[MCHZ]').hasMatch(t)) {
      cmd = t;
      i++;
      if (cmd == 'Z') continue;
    }
    switch (cmd) {
      case 'M':
        cx = double.parse(tok[i]);
        cy = double.parse(tok[i + 1]);
        pts.add((cx, cy));
        i += 2;
      case 'H':
        cx = double.parse(tok[i]);
        pts.add((cx, cy));
        i += 1;
      case 'C':
        for (var k = 0; k < 3; k++) {
          pts.add((
            double.parse(tok[i + 2 * k]),
            double.parse(tok[i + 2 * k + 1]),
          ));
        }
        cx = double.parse(tok[i + 4]);
        cy = double.parse(tok[i + 5]);
        i += 6;
      default:
        i++;
    }
  }
  return pts;
}
