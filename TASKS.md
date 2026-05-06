# porest-desk-app 잔여 작업 리스트

> Claude Code 세션에서 추적 중인 task. 다른 컴퓨터에서 작업 이어갈 때 이 파일 보고 ID 기준으로 진행.
> 완료한 항목은 체크박스 켜고 commit 메시지에 task ID 적기 (예: `feat: ... (#114)`).

## 진행 가이드
- **참조 자료**: `/tmp/porest-screens/` 에 캡쳐된 PNG 13장 (라우트 화면) + 3장 (모달). 새 컴퓨터에서 다시 캡쳐 필요 → `python3 scripts/capture_screens.py` 실행 (porest-desk-front `localhost:3002` 띄운 상태에서)
- **front 미러 기준**: `/Users/lshdainty/study/porest-desk-front/src/` — 같은 부모 디렉토리에 있어야 비교 가능
- **백엔드 실행/DB 수정은 사용자가 직접** — 코드 수정만 자동
- **mock·임시 구현 금지** — API 있으면 무조건 연결
- **N+1 쿼리 사전 점검** — 집계/추이 API 추가 시

---

## 우선순위 1 — 작은 수정 (1~2시간 이내)

- [ ] **#125 TRANSFER(이체) 옵션 재추가**
  - `lib/features/expense/presentation/add_tx_sheet.dart` `_TypeSegment._opts` 에 `('TRANSFER', '이체')` 추가
  - TRANSFER 선택 시 UI 분기:
    - 카테고리 섹션 숨김
    - "보낼 자산" / "받을 자산" 2개 picker 표시
    - 수수료(선택) 입력
    - 제출 시 `assetRepo.createTransfer()` 호출 (이미 존재)
    - 편집 모드(`_isEdit=true`)에선 TRANSFER 옵션 숨김
  - 같은 옵션 추가: `lib/features/preset/presentation/preset_edit_dialog.dart`, `lib/features/recurring/presentation/recurring_edit_dialog.dart` (단, 백엔드 시맨틱 확인 후)

- [ ] **#129 캡쳐 실패 모달 selector 수정 후 재캡쳐**
  - `scripts/capture_modals.py` 의 M02-M05, M07-M09 selector 들이 부정확
  - 브라우저 띄워서 DOM inspect 후 실제 트리거 selector 로 교체
  - 실패 항목: M02 자산추가, M03 자산상세, M04 예산설정, M05 거래상세, M07 메모추가, M08 할일추가, M09 더치페이추가

- [ ] **#131 HideAmountsUnlockDialog 구현 — 금액 숨김 잠금해제**
  - front `HideAmountsUnlockDialog` 미러
  - 현재: hideAmounts 토글이 즉시 on/off
  - 목표: hidden→show 전환 시 PIN/생체 unlock 다이얼로그 거치도록
  - `lib/core/settings/settings_notifier.dart` 확장 + 새 dialog 파일

---

## 우선순위 2 — 화면 디자인 미러 (각 화면당 1~3시간)

각 항목은 `/tmp/porest-screens/{N}-{name}.png` 캡쳐 기준. front 의 모바일 레이아웃과 색·위치·컴포넌트가 일치하도록 재작성.

- [ ] **#114 Expense 화면 미러** — `02-expense.png`
  - `lib/features/expense/presentation/expense_screen.dart`
  - 헤더 m-header 포맷, 월간 요약 카드, 일자별 그룹핑된 거래 리스트, FAB 추가 버튼

- [ ] **#115 Stats 화면 미러** — `03-stats.png`
  - `lib/features/stats/presentation/stats_screen.dart`
  - front 5종 차트(카테고리 도넛/주간 막대/월간 추이/요일·시간대 히트맵 등) 모바일 레이아웃

- [ ] **#116 More 화면 미러** — `04-more.png`
  - `lib/features/more/presentation/more_screen.dart`
  - 메뉴 그룹핑/구분선/아이콘 색·폰트 weight·divider indent 정확히 매칭

- [ ] **#117 Budget 화면 미러** — `06-budget.png`
  - `lib/features/budget/presentation/budget_screen.dart`
  - 카테고리별 예산 진행 바, 전체 예산 요약 카드, 추가 버튼

- [ ] **#118 Calendar 화면 미러** — `07-calendar.png`
  - `lib/features/calendar/presentation/calendar_screen.dart`
  - 월별 그리드 셀 안 이벤트 dot/금액, 선택일 하단 시트 디테일

- [ ] **#119 Todo 화면 미러** — `08-todo.png`
  - `lib/features/todo/presentation/todo_screen.dart`
  - 체크박스/우선순위/날짜 표시, 필터 탭

- [ ] **#120 DutchPay 화면 미러** — `09-dutch-pay.png`
  - `lib/features/dutch_pay/presentation/dutch_pay_screen.dart`
  - 정산 카드, 참여자 아바타, 금액 분배

- [ ] **#121 Memo 화면 미러** — `10-memo.png`
  - `lib/features/memo/presentation/memo_screen.dart`
  - 메모 카드 그리드/리스트, 핀/태그

- [ ] **#122 Group 화면 미러** — `11-group.png`
  - `lib/features/group/presentation/group_screen.dart`
  - 그룹 카드, 멤버 아바타, 잔액

- [ ] **#123 Card-Settings 화면 미러** — `12-card-settings.png`
  - `lib/features/card/presentation/card_screen.dart`
  - 카드 카탈로그·혜택·실적 표시

- [ ] **#124 Settings 화면 미러** — `13-settings.png`
  - `lib/features/settings/presentation/settings_screen.dart`
  - 섹션 그룹·스위치·이동 row

---

## 우선순위 3 — 모달 디자인 미러

- [ ] **#126 AddTxSheet 모달 미러** — `M01-add-tx.png`
  - `lib/features/expense/presentation/add_tx_sheet.dart`
  - 프리셋 칩, 큰 금액 입력(부호 포함), 카테고리 4-col 그리드, 자산 picker, TRANSFER 분기
  - **#125 와 함께 처리하면 효율적**

- [ ] **#127 EventAdd 모달 미러** — `M06-event-add.png`
  - 캘린더 이벤트 추가 모달 재작성

- [ ] **#128 GroupAdd 모달 미러** — `M10-group-add.png`
  - 그룹 추가 모달 재작성

- [ ] **#129 의 모달들** (selector 수정 후 캡쳐되면 각각 미러 작업)

---

## 우선순위 4 — 빠진 기능 추가

- [ ] **#132 거래→더치페이/반복거래 변환 다이얼로그**
  - front `DutchPayFromTxDialog`, `RecurringFromTxDialog` 미러
  - `tx_detail_dialog.dart` 에 액션 추가
  - 양쪽 모두 dialog 컴포넌트 + 핸들러 신규

- [ ] **#133 ExportDialog — CSV/엑셀 내보내기**
  - front `ExportDialog` 미러
  - 거래 데이터 CSV/엑셀 내보내기 (월/카테고리/자산 필터)
  - Settings 또는 More 진입점 결정 필요
  - `share_plus` / `file_picker` 패키지 검토

- [ ] **#134 Asset 다이얼로그 분리 — Add/CardAdd/InvestmentAdd/Detail**
  - 현재 `asset_edit_dialog.dart` 단일 → front 4종 분리
  - `AssetMobile` 의 `TypeGroup onAdd` 가 그룹별로 다른 dialog 호출하도록 수정

---

## 우선순위 5 — v0.2+ 통합/확장

- [ ] **#135 Recurring 자동 실행 + 전일 알림**
  - `RecurringTransaction.autoLog`, `notifyDayBefore` 필드 처리 로직 없음
  - autoLog=Y → nextExecutionDate 도래 시 자동 expense 생성
  - notifyDayBefore=Y → D-1 푸시
  - 백엔드 scheduler vs 클라이언트 결정 필요

- [ ] **#136 Settings 추가 섹션 — 카테고리/예산/반복/알림/계정/데이터**
  - 현재 표시 설정(테마/밀도/금액숨김) 1개만
  - v0.2+ 계획대로 7개 섹션 추가
  - **#124 Settings 미러 작업과 합쳐서 처리 가능**

- [ ] **#137 FilterDialog 백엔드 query param 이동 (v0.2)**
  - 현재 클라이언트 사이드 필터
  - 백엔드 `/expenses` GET query param 으로 이동, 서버 검색
  - 백엔드 endpoint 확장 필요

- [ ] **#139 Group 상세 화면 (v0.5+)**
  - `group_screen.dart:301` — 현재 그룹 카드 + invite code 만
  - 멤버 관리, 거래 공유, 정산 내역 등 미구현

---

## 완료된 작업 (참고)
- [x] #111 Home 화면 — front 디자인 미러 (commit `6dce458`)
- [x] #112 Asset 화면 — front 디자인 미러 (commit `6dce458`)
- [x] #130 Dashboard 하드코드 색 10곳 다크 토큰화 (commit `2acb824`)
- [x] #138 color_parse 에 oklch() CSS 함수 지원 (commit `2acb824`)
