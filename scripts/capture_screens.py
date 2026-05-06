#!/usr/bin/env python3
"""
porest-desk-front 모바일 화면 캡쳐.

흐름:
  1. 헤드 모드 Chromium (iPhone 14 viewport) 띄움
  2. /desk 진입 → 미로그인이면 SSO 로그인 페이지로 redirect
  3. 사용자가 로그인 완료
  4. **터미널에서 Enter 한 번** 누르면 자동 캡쳐 시작
  5. 라우트별 PNG → /tmp/porest-screens/{name}.png
  6. auth.json (storageState) 저장 — 다음 실행 시 로그인 스킵 (--reuse 옵션)

실행:
  python3 scripts/capture_screens.py          # 처음 (로그인 필요)
  python3 scripts/capture_screens.py --reuse  # auth.json 재사용
"""
import sys, time, pathlib, argparse
from playwright.sync_api import sync_playwright

OUT = pathlib.Path("/tmp/porest-screens")
OUT.mkdir(parents=True, exist_ok=True)
AUTH = OUT / "auth.json"

ROUTES = [
    ("01-home",         "/desk"),
    ("02-expense",      "/desk/expense"),
    ("03-stats",        "/desk/stats"),
    ("04-more",         "/desk/more"),
    ("05-asset",        "/desk/asset"),
    ("06-budget",       "/desk/budget"),
    ("07-calendar",     "/desk/calendar"),
    ("08-todo",         "/desk/todo"),
    ("09-dutch-pay",    "/desk/dutch-pay"),
    ("10-memo",         "/desk/memo"),
    ("11-group",        "/desk/group"),
    ("12-card-settings","/desk/card-settings"),
    ("13-settings",     "/desk/settings"),
]

BASE = "http://localhost:3002"

def capture_route(page, name, path):
    out_file = OUT / f"{name}.png"
    print(f"  → {path:30s} → {out_file.name}", flush=True)
    try:
        page.goto(f"{BASE}{path}", wait_until="networkidle", timeout=25000)
        # 데이터 로드 + 애니메이션 + 차트 그려질 시간
        page.wait_for_timeout(3000)
        page.screenshot(path=str(out_file), full_page=True)
    except Exception as e:
        print(f"     ! 실패: {e}", flush=True)
        # 실패해도 일단 현재 화면 캡쳐
        try:
            page.screenshot(path=str(out_file), full_page=True)
        except Exception:
            pass

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--reuse", action="store_true", help="auth.json 재사용")
    args = ap.parse_args()

    with sync_playwright() as p:
        iphone = p.devices["iPhone 14"]
        browser = p.chromium.launch(headless=False)
        ctx_kwargs = dict(iphone, locale="ko-KR")
        if args.reuse and AUTH.exists():
            ctx_kwargs["storage_state"] = str(AUTH)
            print(f"→ auth.json 재사용", flush=True)
        ctx = browser.new_context(**ctx_kwargs)
        page = ctx.new_page()

        page.goto(f"{BASE}/desk", wait_until="domcontentloaded")

        if not args.reuse:
            sentinel = OUT / "proceed"
            sentinel.unlink(missing_ok=True)
            print(f"\n→ 브라우저에서 로그인하세요.", flush=True)
            print(f"→ 로그인 완료되면 다음 명령 실행:  touch {sentinel}", flush=True)
            print(f"  (또는 캡쳐 시작 신호로 사용)\n", flush=True)
            deadline = time.time() + 600
            while time.time() < deadline and not sentinel.exists():
                time.sleep(1)
            if not sentinel.exists():
                print("✗ 타임아웃 (10분)", flush=True)
                browser.close()
                sys.exit(1)
            sentinel.unlink(missing_ok=True)
            try:
                ctx.storage_state(path=str(AUTH))
                print(f"✓ auth.json 저장됨 → {AUTH}", flush=True)
            except Exception as e:
                print(f"  ! storage_state 저장 실패: {e}", flush=True)

        print(f"\n→ 캡쳐 시작 ({len(ROUTES)} routes)")
        for name, path in ROUTES:
            capture_route(page, name, path)

        print(f"\n✓ 완료. {OUT} 에 PNG 저장됨.", flush=True)
        print(f"  브라우저는 60초 후 자동 종료. 즉시 종료: Ctrl-C", flush=True)
        try:
            time.sleep(60)
        except KeyboardInterrupt:
            pass
        browser.close()

if __name__ == "__main__":
    main()
