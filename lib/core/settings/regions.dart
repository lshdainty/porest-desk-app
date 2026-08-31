/// 표시 기준 지역 목록. 값은 IANA 타임존 ID (web `shared/lib/regions.ts` 와 동일 목록).
///
/// 400여 개 IANA 존을 전부 노출하면 고르기 어려워 실제 사용이 있을 법한 지역만 추린다.
class RegionOption {
  const RegionOption(this.value, this.ko, this.en);
  final String value;
  final String ko;
  final String en;
}

const kRegionOptions = <RegionOption>[
  RegionOption('Asia/Seoul', '대한민국 (서울)', 'South Korea (Seoul)'),
  RegionOption('Asia/Tokyo', '일본 (도쿄)', 'Japan (Tokyo)'),
  RegionOption('Asia/Shanghai', '중국 (상하이)', 'China (Shanghai)'),
  RegionOption('Asia/Hong_Kong', '홍콩', 'Hong Kong'),
  RegionOption('Asia/Singapore', '싱가포르', 'Singapore'),
  RegionOption('Asia/Bangkok', '태국 (방콕)', 'Thailand (Bangkok)'),
  RegionOption('Asia/Kolkata', '인도 (콜카타)', 'India (Kolkata)'),
  RegionOption('Asia/Dubai', '아랍에미리트 (두바이)', 'UAE (Dubai)'),
  RegionOption('Australia/Sydney', '호주 (시드니)', 'Australia (Sydney)'),
  RegionOption('Europe/London', '영국 (런던)', 'United Kingdom (London)'),
  RegionOption('Europe/Paris', '프랑스 (파리)', 'France (Paris)'),
  RegionOption('Europe/Berlin', '독일 (베를린)', 'Germany (Berlin)'),
  RegionOption('America/New_York', '미국 동부 (뉴욕)', 'US Eastern (New York)'),
  RegionOption('America/Chicago', '미국 중부 (시카고)', 'US Central (Chicago)'),
  RegionOption('America/Denver', '미국 산악 (덴버)', 'US Mountain (Denver)'),
  RegionOption(
    'America/Los_Angeles',
    '미국 서부 (로스앤젤레스)',
    'US Pacific (Los Angeles)',
  ),
  RegionOption('America/Sao_Paulo', '브라질 (상파울루)', 'Brazil (Sao Paulo)'),
  RegionOption('UTC', 'UTC (협정 세계시)', 'UTC (Coordinated Universal Time)'),
];

/// 저장된 값이 목록에 없을 수도 있어(가입 후 목록 변경 등) 현재 값을 옵션에 끼워 넣는다.
List<RegionOption> regionOptionsWith(String? current) {
  if (current == null ||
      current.isEmpty ||
      kRegionOptions.any((o) => o.value == current)) {
    return kRegionOptions;
  }
  return [RegionOption(current, current, current), ...kRegionOptions];
}
