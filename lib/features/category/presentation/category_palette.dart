/// 카테고리 아이콘 후보 — 웹 `CategoryEditDialog.tsx` `ICON_CHOICES` 34개 1:1 미러.
/// (lucide-react kebab 이름, `lucideByName` 으로 IconData 매핑.)
///
/// 색상 팔레트는 차트 10색(`kChartBaseHexes`, chart_palette.dart)을 사용 —
/// 종전 이 파일의 `CatPalette.all` 12색은 미사용 dead code 라 제거함.
const List<String> kCategoryIcons = [
  'utensils', 'coffee', 'bus', 'shopping-bag', 'home', 'heart-pulse',
  'ticket', 'receipt-text', 'book-open', 'piggy-bank', 'arrow-down-to-line',
  'car', 'plane', 'gift', 'dumbbell', 'gamepad-2', 'film', 'music',
  'baby', 'paw-print', 'shirt', 'sparkles', 'wrench', 'fuel',
  'pill', 'phone', 'wifi', 'tv', 'briefcase', 'graduation-cap',
  'trending-up', 'hand-coins', 'landmark', 'tag',
];
