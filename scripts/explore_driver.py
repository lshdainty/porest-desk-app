#!/usr/bin/env python3
"""
Persistent playwright driver — 백그라운드 실행, JSON 명령으로 제어.

기본 동작:
- iPhone 14 viewport, headed, 사용자가 직접 보면서 작업
- /tmp/pw-cmd/cmd-N.json 에 명령 쓰면 → 실행 → /tmp/pw-out/cmd-N.json 응답
- /tmp/pw-cmd/save_auth 파일 touch 하면 storage_state 저장

지원 op:
  goto, click, click_text, screenshot, back, url, wait, list_clickable, evaluate, exit
"""
import json, pathlib, time, traceback
from playwright.sync_api import sync_playwright

CMD_DIR = pathlib.Path("/tmp/pw-cmd")
OUT_DIR = pathlib.Path("/tmp/pw-out")
SCR_DIR = pathlib.Path("/tmp/pw-scr")
AUTH = pathlib.Path("/tmp/porest-screens/auth.json")
BASE = "http://localhost:3002"

for d in (CMD_DIR, OUT_DIR, SCR_DIR):
    d.mkdir(parents=True, exist_ok=True)


def execute(page, cmd):
    op = cmd["op"]
    if op == "goto":
        page.goto(cmd["url"], wait_until=cmd.get("wait_until", "networkidle"), timeout=15000)
        page.wait_for_timeout(800)
        return {"url": page.url}
    if op == "click":
        loc = page.locator(cmd["selector"]).first
        loc.wait_for(timeout=cmd.get("timeout", 5000))
        loc.click()
        page.wait_for_timeout(cmd.get("after", 500))
        return {"url": page.url}
    if op == "click_text":
        page.get_by_text(cmd["text"], exact=cmd.get("exact", False)).first.click()
        page.wait_for_timeout(cmd.get("after", 500))
        return {"url": page.url}
    if op == "click_role":
        page.get_by_role(cmd["role"], name=cmd.get("name")).first.click()
        page.wait_for_timeout(cmd.get("after", 500))
        return {"url": page.url}
    if op == "fill":
        page.locator(cmd["selector"]).first.fill(cmd["value"])
        return {}
    if op == "press":
        page.keyboard.press(cmd["key"])
        page.wait_for_timeout(cmd.get("after", 300))
        return {}
    if op == "screenshot":
        path = SCR_DIR / cmd["name"]
        page.screenshot(path=str(path), full_page=cmd.get("full_page", True))
        return {"path": str(path)}
    if op == "back":
        page.go_back()
        page.wait_for_timeout(500)
        return {"url": page.url}
    if op == "url":
        return {"url": page.url}
    if op == "wait":
        page.wait_for_timeout(cmd.get("ms", 1000))
        return {}
    if op == "list_clickable":
        sel = cmd.get("selector", "button, a, [role='button'], [data-tx-row], [data-card-row]")
        elements = page.locator(sel).all()
        out = []
        limit = cmd.get("limit", 80)
        for e in elements[:limit]:
            try:
                if not e.is_visible():
                    continue
                box = e.bounding_box()
                if not box:
                    continue
                text = (e.text_content() or "").strip()[:80]
                aria = e.get_attribute("aria-label") or ""
                href = e.get_attribute("href") or ""
                out.append({"text": text, "aria": aria, "href": href, "box": box})
            except Exception:
                pass
        return {"items": out, "count": len(out)}
    if op == "evaluate":
        return {"result": page.evaluate(cmd["js"])}
    if op == "title":
        return {"title": page.title()}
    if op == "outer_html":
        sel = cmd.get("selector", "body")
        html = page.locator(sel).first.evaluate("el => el.outerHTML")
        return {"html": html[: cmd.get("limit", 20000)]}
    if op == "exit":
        return {"exit": True}
    raise ValueError(f"unknown op: {op}")


def main():
    for f in CMD_DIR.glob("cmd-*.json"):
        f.unlink()
    for f in OUT_DIR.glob("cmd-*.json"):
        f.unlink()
    save_auth_sentinel = CMD_DIR / "save_auth"
    save_auth_sentinel.unlink(missing_ok=True)

    with sync_playwright() as p:
        iphone = p.devices["iPhone 14"]
        browser = p.chromium.launch(headless=False, args=["--window-position=80,80"])
        ctx_kwargs = dict(iphone, locale="ko-KR")
        if AUTH.exists():
            ctx_kwargs["storage_state"] = str(AUTH)
        ctx = browser.new_context(**ctx_kwargs)
        page = ctx.new_page()

        try:
            page.goto(f"{BASE}/desk", wait_until="domcontentloaded", timeout=15000)
        except Exception:
            pass

        print(f"DRIVER READY url={page.url}", flush=True)

        seq = 0
        while True:
            if save_auth_sentinel.exists():
                try:
                    save_auth_sentinel.unlink()
                    ctx.storage_state(path=str(AUTH))
                    print(f"AUTH SAVED to {AUTH}", flush=True)
                except Exception as e:
                    print(f"AUTH SAVE FAIL: {e}", flush=True)
                continue

            cmd_file = CMD_DIR / f"cmd-{seq}.json"
            while not cmd_file.exists() and not save_auth_sentinel.exists():
                time.sleep(0.2)
            if save_auth_sentinel.exists():
                continue

            try:
                cmd = json.loads(cmd_file.read_text())
            except Exception as e:
                (OUT_DIR / f"cmd-{seq}.json").write_text(json.dumps({"ok": False, "error": f"parse: {e}"}))
                cmd_file.unlink(missing_ok=True)
                seq += 1
                continue
            cmd_file.unlink(missing_ok=True)

            try:
                result = execute(page, cmd)
                (OUT_DIR / f"cmd-{seq}.json").write_text(
                    json.dumps({"ok": True, **result}, ensure_ascii=False)
                )
                if result.get("exit"):
                    break
            except Exception as e:
                (OUT_DIR / f"cmd-{seq}.json").write_text(
                    json.dumps(
                        {"ok": False, "error": str(e), "trace": traceback.format_exc()[:2000]},
                        ensure_ascii=False,
                    )
                )
            seq += 1

        browser.close()


if __name__ == "__main__":
    main()
