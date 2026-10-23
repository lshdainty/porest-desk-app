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
