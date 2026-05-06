# porest-desk-app 잔여 작업 리스트

> Claude Code 세션에서 추적 중인 task. 다른 컴퓨터에서 작업 이어갈 때 이 파일 보고 ID 기준으로 진행.
> 완료한 항목은 체크박스 켜고 commit 메시지에 task ID 적기 (예: `feat: ... (#114)`).

## 진행 가이드
- **참조 자료 (front)**: `git clone https://github.com/lshdainty/porest-desk-front.git` 후 `src/` 참조 — Claude Code on the Web 컨테이너에서도 git clone 가능
- **참조 자료 (back)**: `git clone https://github.com/lshdainty/porest-desk-back.git` — API/스케줄러 시그니처 확인용
- **캡쳐 PNG**: `/tmp/porest-screens/` (필요 시 `python3 scripts/capture_screens.py`, porest-desk-front `localhost:3002` 띄운 상태)
- **백엔드 실행/DB 수정은 사용자가 직접** — 코드 수정만 자동
- **mock·임시 구현 금지** — API 있으면 무조건 연결
- **N+1 쿼리 사전 점검** — 집계/추이 API 추가 시
- **컨테이너 push 권한 이슈**: GitHub App 의 Contents:write 권한 + 레포 설치 필요. 권한 풀리기 전엔 commit 만 누적, push 는 권한 부여 후 일괄.

---

## 우선순위 1 — 작은 수정 (1~2시간 이내)

- [x] **#125 TRANSFER(이체) 옵션 재추가** (commit `55d2146`)
  - `add_tx_sheet.dart` `_TypeSegment._opts` 에 `('TRANSFER','이체')` 추가
  - TRANSFER 선택 시 카테고리/가맹점/결제수단 섹션 숨김, 보낼/받을 자산 picker + 수수료
  - 제출 시 `assetRepo.createTransfer()` 분기 호출, 편집 모드선 옵션 숨김
  - **잔여**: `preset_edit_dialog.dart`, `recurring_edit_dialog.dart` 에 TRANSFER 옵션 추가는 백엔드 시맨틱 확인 후 별도 처리

- [ ] **#129 캡쳐 실패 모달 selector 수정 후 재캡쳐** (BLOCKED — 컨테이너에 브라우저 없음)
  - `scripts/capture_modals.py` 의 M02-M05, M07-M09 selector 들이 부정확
  - 실패 항목: M02 자산추가, M03 자산상세, M04 예산설정, M05 거래상세, M07 메모추가, M08 할일추가, M09 더치페이추가
  - 로컬 PC 에서 직접 처리 필요

- [x] **#131 HideAmountsUnlockDialog 구현 — 금액 숨김 잠금해제** (commit `ba20640`)
  - `core/auth/auth_repository.dart` 에 `verifyPassword(password)` 추가 (POST `/users/me/verify-password`)
  - `core/settings/settings_notifier.dart` 에 `setHideAmounts(bool)` 추가
  - `core/settings/hide_amounts_unlock_dialog.dart` 신규 — 잠금 해제(true→false) 시 비밀번호 검증
  - `mobile_header.dart` / `asset_screen.dart` 토글 호출부 → `toggleHideAmountsWithUnlock` 으로 교체

---

## 우선순위 2 — 화면 디자인 미러 (각 화면당 1~3시간)

> 기존 화면들은 이미 동작 가능한 상태로 구현돼 있음. 픽셀 미러 폴리시는 캡쳐 PNG 검증이 필요해 컨테이너에서 진행 어려움. 로컬 PC 에서 화면 띄워보면서 진행 권장.

- [ ] **#114 Expense 화면 미러** — `02-expense.png`
  - `lib/features/expense/presentation/expense_screen.dart`
  - 헤더 m-header 포맷, 월간 요약 카드, 일자별 그룹핑된 거래 리스트, FAB 추가 버튼
- [ ] **#115 Stats 화면 미러** — `03-stats.png`
- [ ] **#116 More 화면 미러** — `04-more.png`
- [ ] **#117 Budget 화면 미러** — `06-budget.png`
- [ ] **#118 Calendar 화면 미러** — `07-calendar.png`
- [ ] **#119 Todo 화면 미러** — `08-todo.png`
- [ ] **#120 DutchPay 화면 미러** — `09-dutch-pay.png`
- [ ] **#121 Memo 화면 미러** — `10-memo.png`
- [ ] **#122 Group 화면 미러** — `11-group.png` (#139 상세 화면은 이미 구현됨 — 리스트 컴포넌트 폴리시만 남음)
- [ ] **#123 Card-Settings 화면 미러** — `12-card-settings.png`
- [x] **#124 Settings 화면 미러** — `13-settings.png` (commit `6b89258`, #136 와 통합 처리)
  - 9개 섹션 그룹핑, 카테고리/계좌·카드/예산/반복/프리셋/알림 → 기존 라우트로 push
  - 표시 설정: AppearanceSection inline
  - 데이터 내보내기: showExportDialog
  - 계정 섹션: 사용자 정보 + 로그아웃

---

## 우선순위 3 — 모달 디자인 미러

> 픽셀 미러 폴리시는 캡쳐 검증이 필요. 기능적으로는 이미 동작.

- [ ] **#126 AddTxSheet 모달 미러** — `M01-add-tx.png` (#125 TRANSFER 분기는 이미 구현됨)
- [ ] **#127 EventAdd 모달 미러** — `M06-event-add.png`
- [ ] **#128 GroupAdd 모달 미러** — `M10-group-add.png`
- [ ] **#129 의 모달들** — selector 수정 후 (#129 BLOCKED)

---

## 우선순위 4 — 빠진 기능 추가

- [x] **#132 거래→더치페이/반복거래 변환 다이얼로그** (commit `47c3342`)
  - `tx_detail_dialog.dart` 에 "더치페이로" 버튼 추가
  - `DutchPayCreateDialog(fromExpense:)` — title/금액/날짜 미리채움 + sourceExpenseRowId 전달
  - `DutchPayRepository.create` 에 sourceExpenseRowId 파라미터 추가
  - 반복 거래 변환 (`showRecurringEditDialog(fromExpense:)`)은 이미 `tx_detail_dialog` 에 구현돼 있던 상태

- [x] **#133 ExportDialog — CSV 내보내기** (commit `4be832e`)
  - `pubspec.yaml` 에 `share_plus: ^10.1.4` 추가 (`flutter pub get` 필요)
  - `features/expense/presentation/export_dialog.dart` 신규
    - 기간(주간/이번 달/분기/올해/직접 선택) + 포함(거래/카테고리/자산) 선택
    - GET `/expenses` + categories + 자산 → CSV 빌드 → Share.shareXFiles
  - More 화면에 "내보내기" 진입점 추가
  - **잔여**: xlsx/PDF 포맷은 별도 패키지(`excel`, `pdf`) 필요 — 추후 작업

- [x] **#134 Asset 다이얼로그 분리 — Add/CardAdd/InvestmentAdd/Detail** (commit `ca09156`)
  - `asset_edit_dialog.dart` 진입점 4종 신설:
    - `showAssetAddDialog(context, presetType?)` — 일반
    - `showCardAddDialog(context)` — CREDIT_CARD/CHECK_CARD chip 만 노출
    - `showInvestmentAddDialog(context)` — INVESTMENT chip 만
    - `showAssetDetailDialog(context, asset)` — 수정/삭제
  - `AssetMobile` `_TypeGroup` 에 `_GroupKind` enum 추가, 그룹별 "추가" 버튼이 적절한 다이얼로그 호출
  - `showAssetEditDialog` 는 backcompat wrapper 로 유지
  - **잔여**: front `CardAddDialog`/`InvestmentAddDialog` 의 카드 카탈로그·증권사 카탈로그 매핑은 v0.2+ 에서 별도 (현재는 일반 폼 + 자산 종류 chip 제한만)

---

## 우선순위 5 — v0.2+ 통합/확장

- [x] **#135 Recurring 자동 실행 + 전일 알림** (서버측 구현 확인)
  - `autoLog=Y` → 백엔드 `RecurringTransactionScheduler` (`@Scheduled(cron = "0 0 0 * * *")`) 가 daily 실행 — **클라이언트 작업 불필요**
  - **잔여 — defer**: `notifyDayBefore=Y` D-1 푸시는 `flutter_local_notifications` + 플랫폼 설정(AndroidManifest, iOS plist) 필요. 컨테이너에서 검증 불가하므로 별도 작업으로 분리.

- [x] **#136 Settings 추가 섹션 — 카테고리/예산/반복/알림/계정/데이터** (#124 와 통합 처리, commit `6b89258`)

- [ ] **#137 FilterDialog 백엔드 query param 이동 (v0.2)** — defer
  - 백엔드 `/expenses` GET 은 `categoryId`, `assetId` (단일) 만 지원
  - multi-select 필터링은 백엔드 endpoint 확장(List 파라미터) 필요 — 백엔드 작업 후 클라이언트 연결

- [x] **#139 Group 상세 화면** (commit `?`)
  - `domain/group_member.dart` 신규 (plain class, freezed 회피)
  - `GroupRepository` 에 getDetail / removeMember / changeMemberRole 추가
  - `groupDetailProvider` family<int> 신설
  - `presentation/group_detail_screen.dart` 신규
    - 그룹 헤더, 초대 코드(복사 + 재발급), 멤버 리스트(역할 배지/메뉴)
  - `/groups/:id` 라우트 등록, `group_screen` 탭 시 navigate
  - **잔여**: 거래 공유, 정산 내역 등 그룹 거래 관련 기능은 별도 (#137 백엔드 multi-select 와 연계)

---

## 완료된 작업 (참고)

### 이전 세션
- [x] #111 Home 화면 — front 디자인 미러 (commit `6dce458`)
- [x] #112 Asset 화면 — front 디자인 미러 (commit `6dce458`)
- [x] #130 Dashboard 하드코드 색 10곳 다크 토큰화 (commit `2acb824`)
- [x] #138 color_parse 에 oklch() CSS 함수 지원 (commit `2acb824`)

### 이번 세션 (요약)
- [x] #125 TRANSFER 이체 옵션 (`55d2146`)
- [x] #131 HideAmountsUnlockDialog (`ba20640`)
- [x] #133 ExportDialog CSV (`4be832e`)
- [x] #134 Asset 다이얼로그 4종 분리 (`ca09156`)
- [x] #132 Tx → DutchPay/Recurring 변환 (`47c3342`)
- [x] #124 + #136 Settings 7섹션 (`6b89258`)
- [x] #139 Group 상세 화면

### 후속 적용 필요
- `flutter pub get` — `share_plus` 패키지 다운로드 필요 (#133)
- 컨테이너 GitHub App 권한 풀린 뒤 `git push -u origin claude/review-pending-work-4btvY`
- iOS 빌드 시 `share_plus` 의 Info.plist `LSApplicationQueriesSchemes` 자동 처리됨 (변경 없음 예상)
