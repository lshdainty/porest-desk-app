import 'dart:convert';

/// 백엔드 `ConstellationApiDto` 매핑 (plain class — dashboard_summary 관례).
/// 별자리 모양 star_map: {"pts":[[x,y]...],"edges":[[a,b]...]} 0-100 정규 좌표.
class StarMapData {
  const StarMapData({required this.pts, required this.edges});
  final List<List<double>> pts;
  final List<List<int>> edges;

  static StarMapData parse(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final pts = (j['pts'] as List<dynamic>? ?? const [])
          .map((p) => (p as List<dynamic>)
              .map((v) => (v as num).toDouble())
              .toList(growable: false))
          .toList(growable: false);
      final edges = (j['edges'] as List<dynamic>? ?? const [])
          .map((e) => (e as List<dynamic>)
              .map((v) => (v as num).toInt())
              .toList(growable: false))
          .toList(growable: false);
      return StarMapData(pts: pts, edges: edges);
    } catch (_) {
      return const StarMapData(pts: [], edges: []);
    }
  }
}

class ConstellationInfo {
  const ConstellationInfo({
    required this.rowId,
    required this.constellationKey,
    required this.name,
    required this.description,
    required this.colorKey,
    required this.starCount,
    required this.starMapRaw,
    required this.sortOrder,
  });
  final int rowId;
  final String constellationKey;
  final String name;
  final String? description;
  final String colorKey;
  final int starCount;
  final String starMapRaw;
  final int sortOrder;

  StarMapData get starMap => StarMapData.parse(starMapRaw);

  factory ConstellationInfo.fromJson(Map<String, dynamic> j) {
    return ConstellationInfo(
      rowId: (j['rowId'] as num?)?.toInt() ?? 0,
      constellationKey: j['constellationKey'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String?,
      colorKey: j['colorKey'] as String? ?? 'blue',
      starCount: (j['starCount'] as num?)?.toInt() ?? 0,
      starMapRaw: j['starMap'] as String? ?? '{"pts":[],"edges":[]}',
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class ConstellationToday {
  const ConstellationToday({
    required this.constellation,
    required this.points,
    required this.goal,
    required this.collected,
    required this.todoPoints,
    required this.memoPoints,
    required this.streak,
    required this.guardCount,
    required this.totalCollected,
  });
  final ConstellationInfo constellation;
  final int points;
  final int goal;
  final bool collected;
  final int todoPoints;
  final int memoPoints;
  final int streak;
  final int guardCount;
  final int totalCollected;

  factory ConstellationToday.fromJson(Map<String, dynamic> j) {
    int p(String k) => (j[k] as num?)?.toInt() ?? 0;
    return ConstellationToday(
      constellation:
          ConstellationInfo.fromJson(j['constellation'] as Map<String, dynamic>? ?? const {}),
      points: p('points'),
      goal: p('goal'),
      collected: j['collected'] as bool? ?? false,
      todoPoints: p('todoPoints'),
      memoPoints: p('memoPoints'),
      streak: p('streak'),
      guardCount: p('guardCount'),
      totalCollected: p('totalCollected'),
    );
  }
}

/// 나의 밤하늘 하루 — status: GROWN(수집) | WITHERED(흐린 밤) | REST(쉼).
class SkyDay {
  const SkyDay({
    required this.date,
    required this.status,
    required this.constellationKey,
    required this.colorKey,
    required this.points,
    required this.guardUsed,
  });
  final String date;
  final String status;
  final String? constellationKey;
  final String? colorKey;
  final int points;
  final bool guardUsed;

  bool get isGrown => status == 'GROWN';
  bool get isWithered => status == 'WITHERED';

  factory SkyDay.fromJson(Map<String, dynamic> j) {
    return SkyDay(
      date: j['date'] as String? ?? '',
      status: j['status'] as String? ?? 'REST',
      constellationKey: j['constellationKey'] as String?,
      colorKey: j['colorKey'] as String?,
      points: (j['points'] as num?)?.toInt() ?? 0,
      guardUsed: j['guardUsed'] as bool? ?? false,
    );
  }
}

class CollectionEntry {
  const CollectionEntry({
    required this.constellation,
    required this.collectCount,
    required this.lastCollectedDate,
  });
  final ConstellationInfo constellation;
  final int collectCount;
  final String? lastCollectedDate;

  bool get collected => collectCount > 0;

  factory CollectionEntry.fromJson(Map<String, dynamic> j) {
    return CollectionEntry(
      constellation:
          ConstellationInfo.fromJson(j['constellation'] as Map<String, dynamic>? ?? const {}),
      collectCount: (j['collectCount'] as num?)?.toInt() ?? 0,
      lastCollectedDate: j['lastCollectedDate'] as String?,
    );
  }
}

class ConstellationCollectionData {
  const ConstellationCollectionData({
    required this.entries,
    required this.collectedKinds,
    required this.totalCollected,
  });
  final List<CollectionEntry> entries;
  final int collectedKinds;
  final int totalCollected;

  factory ConstellationCollectionData.fromJson(Map<String, dynamic> j) {
    return ConstellationCollectionData(
      entries: (j['entries'] as List<dynamic>? ?? const [])
          .map((e) => CollectionEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      collectedKinds: (j['collectedKinds'] as num?)?.toInt() ?? 0,
      totalCollected: (j['totalCollected'] as num?)?.toInt() ?? 0,
    );
  }
}
