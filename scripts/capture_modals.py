#!/usr/bin/env python3
"""
porest-desk-front 모바일 화면의 모달/다이얼로그/시트 캡쳐.

각 라우트로 이동 → 특정 트리거 (FAB, + 버튼, 행 클릭 등) → 모달 떠오르면 캡쳐.

실행: python3 scripts/capture_modals.py --reuse
"""
import sys, time, pathlib, argparse
from playwright.sync_api import sync_playwright

OUT = pathlib.Path("/tmp/porest-screens")
OUT.mkdir(parents=True, exist_ok=True)
AUTH = OUT / "auth.json"
BASE = "http://localhost:3002"

# (이름, 라우트, 트리거 selector, 모달 떠오를 때까지 기다릴 selector)
SCENARIOS = [
    # 거래 추가 시트 — 중앙 FAB 클릭
    ("M01-add-tx",        "/desk",         "button:has(span > svg.lucide-plus)",   "[role='dialog']"),
    # 자산 추가 — /desk/asset 의 + 추가 button
    ("M02-asset-add",     "/desk/asset",   "button:has-text('+ 추가')",            "[role='dialog']"),
    # 자산 카드(계좌) 클릭 → 상세
    ("M03-asset-detail",  "/desk/asset",   ".tx-row, [data-card-row]",             "[role='dialog']"),
    # 예산 설정
    ("M04-budget-settings","/desk/budget", "button:has-text('예산 설정')",         "[role='dialog']"),
    # 거래 행 클릭 → 상세
    ("M05-tx-detail",     "/desk/expense", "button[data-tx-row], .tx-row",         "[role='dialog']"),
    # 캘린더 이벤트 추가 (FAB)
    ("M06-event-add",     "/desk/calendar","button:has(svg.lucide-plus)",          "[role='dialog']"),
    # 메모 추가
    ("M07-memo-add",      "/desk/memo",    "button:has-text('메모 추가')",         "[role='dialog']"),
    # 할 일 추가
    ("M08-todo-add",      "/desk/todo",    "button:has-text('할 일 추가')",        "[role='dialog']"),
    # 더치페이 만들기
    ("M09-dutch-add",     "/desk/dutch-pay","button:has-text('정산 만들기')",       "[role='dialog']"),
    # 그룹 만들기
    ("M10-group-add",     "/desk/group",   "button:has-text('그룹 추가')",         "[role='dialog']"),
]

def capture(page, name, route, trigger, dialog_sel, attempt=0):
    out = OUT / f"{name}.png"
    print(f"  → {route:18s}  trigger={trigger[:40]}  → {out.name}", flush=True)
    try:
        page.goto(f"{BASE}{route}", wait_until="networkidle", timeout=20000)
        page.wait_for_timeout(1500)
        # 트리거 클릭 — 첫 번째 매칭만
        loc = page.locator(trigger).first
        loc.wait_for(timeout=8000)
        loc.click()
        # 모달 떠오를 때까지
        page.locator(dialog_sel).first.wait_for(timeout=5000)
        page.wait_for_timeout(800)  # 애니메이션
        page.screenshot(path=str(out), full_page=True)
        # ESC 로 닫기 (다음 시나리오를 위해)
        page.keyboard.press("Escape")
        page.wait_for_timeout(500)
    except Exception as e:
        print(f"     ! 실패: {e}", flush=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--reuse", action="store_true")
    args = ap.parse_args()

    with sync_playwright() as p:
        iphone = p.devices["iPhone 14"]
        browser = p.chromium.launch(headless=False)
        ctx_kwargs = dict(iphone, locale="ko-KR")
        if args.reuse and AUTH.exists():
            ctx_kwargs["storage_state"] = str(AUTH)
        ctx = browser.new_context(**ctx_kwargs)
        page = ctx.new_page()
        page.goto(f"{BASE}/desk", wait_until="domcontentloaded")

        if not args.reuse:
            sentinel = OUT / "proceed"
            sentinel.unlink(missing_ok=True)
            print(f"\n→ 로그인 후 sentinel: touch {sentinel}", flush=True)
            while not sentinel.exists():
                time.sleep(1)
            sentinel.unlink(missing_ok=True)
            ctx.storage_state(path=str(AUTH))

        print(f"\n→ 모달 캡쳐 시작 ({len(SCENARIOS)} scenarios)")
        for s in SCENARIOS:
            capture(page, *s)

        print(f"\n✓ 완료. {OUT}", flush=True)
        time.sleep(30)
        browser.close()

if __name__ == "__main__":
    main()
