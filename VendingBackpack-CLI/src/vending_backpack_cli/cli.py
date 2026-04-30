from __future__ import annotations

import argparse
import getpass
import json
import os
import subprocess
import sys
from pathlib import Path

from .api import VbpApi
from .session_store import SessionData, SessionStore


def _base_url() -> str:
    return os.environ.get("VBP_API_BASE_URL", "http://127.0.0.1:9090/api").rstrip("/")


def _session_store() -> SessionStore:
    home = os.environ.get("HOME", ".")
    return SessionStore(f"{home}/.vending-backpack/session.json")


def _surface_control_path() -> Path:
    home = os.environ.get("HOME", ".")
    return Path(home) / ".vending-backpack" / "surface-control.json"


def _clear_surface_control() -> None:
    path = _surface_control_path()
    if path.exists():
        path.unlink()


def _dart_app_path() -> Path:
    repo_root = Path(__file__).resolve().parents[3]
    return repo_root / "Frontend" / "build" / "macos" / "Build" / "Products" / "Debug" / "vending_backpack_v2.app"


def _print(obj: dict, as_json: bool) -> None:
    if as_json:
        print(json.dumps(obj, indent=2, sort_keys=True))
        return
    print(json.dumps(obj, indent=2, sort_keys=True))


def _choice(prompt: str, options: list[str]) -> int:
    print(prompt)
    for index, option in enumerate(options, start=1):
        print(f"{index}. {option}")
    while True:
        raw = input("> ").strip()
        if raw.isdigit():
            selection = int(raw)
            if 1 <= selection <= len(options):
                return selection
        print(f"Enter a number from 1 to {len(options)}.")


def _save_surface(target: str) -> dict:
    path = _surface_control_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {"target": target, "importSession": True}
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    return {
        "status": "ok",
        "target": target,
        "path": str(path),
    }


def _run_login_wizard(api: VbpApi, store: SessionStore, as_json: bool) -> None:
    print("Login Wizard")
    email = input("Email: ").strip()
    password = getpass.getpass("Password: ")
    org = input("Organization ID (optional): ").strip() or None
    response = api.login(email=email, password=password, organization_id=org)
    token = str(response.get("access_token", ""))
    if not token:
        raise RuntimeError("Missing access token")
    api.set_access_token(token)
    store.save(SessionData(access_token=token, user=dict(response.get("user", {}))))
    _print(response, as_json)


def _run_surface_wizard(as_json: bool) -> None:
    targets = [
        "auth-login",
        "auth-register",
        "dashboard",
        "routes",
        "warehouse",
        "settings",
    ]
    choice = _choice("Choose Dart app surface", targets)
    _print(_save_surface(targets[choice - 1]), as_json)


def _launch_dart_app(target: str | None, as_json: bool) -> None:
    if target:
        _save_surface(target)
    app_path = _dart_app_path()
    if not app_path.exists():
        raise RuntimeError(f"Dart app build not found: {app_path}")
    subprocess.run(["open", str(app_path)], check=True)
    payload = {
        "status": "ok",
        "launched": str(app_path),
    }
    if target:
        payload["target"] = target
    _print(payload, as_json)


def _run_main_wizard(api: VbpApi, store: SessionStore, session: SessionData | None, as_json: bool) -> None:
    options = [
        "Login",
        "Who am I",
        "Backend health",
        "Surface control for Dart app",
        "Launch Dart app",
        "Logout",
        "Exit",
    ]
    while True:
        selection = _choice("VendingBackpack CLI", options)
        if selection == 1:
            _run_login_wizard(api, store, as_json)
        elif selection == 2:
            if session is None:
                session = store.load()
                if session is not None:
                    api.set_access_token(session.access_token)
            if session is None:
                print("Not signed in.")
            else:
                _print(api.me(), as_json)
        elif selection == 3:
            _print(api.health(), as_json)
        elif selection == 4:
            _run_surface_wizard(as_json)
        elif selection == 5:
            target_options = [
                "dashboard",
                "routes",
                "warehouse",
                "settings",
                "auth-login",
                "auth-register",
            ]
            target_choice = _choice("Choose startup surface", target_options)
            _launch_dart_app(target_options[target_choice - 1], as_json)
        elif selection == 6:
            store.clear()
            _clear_surface_control()
            api.set_access_token(None)
            session = None
            print("Session cleared.")
        else:
            return


def main() -> None:
    parser = argparse.ArgumentParser(prog="vbp")
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("wizard")
    sub.add_parser("health")
    sub.add_parser("login")
    sub.add_parser("logout")
    sub.add_parser("status")
    sub.add_parser("whoami")
    launch = sub.add_parser("launch")
    launch.add_argument(
        "--target",
        choices=["auth-login", "auth-register", "dashboard", "routes", "warehouse", "settings"],
    )
    surface = sub.add_parser("surface")
    surface.add_argument(
        "--target",
        choices=["auth-login", "auth-register", "dashboard", "routes", "warehouse", "settings"],
    )
    args = parser.parse_args()

    api = VbpApi(_base_url())
    store = _session_store()
    session = store.load()
    if session:
        api.set_access_token(session.access_token)

    try:
        if args.command in {None, "wizard"}:
            _run_main_wizard(api, store, session, args.json)
        elif args.command == "health":
            _print(api.health(), args.json)
        elif args.command == "login":
            _run_login_wizard(api, store, args.json)
        elif args.command in {"status", "whoami"}:
            if not session:
                print("Not signed in.")
                return
            _print(api.me(), args.json)
        elif args.command == "logout":
            store.clear()
            _clear_surface_control()
            print("Session cleared.")
        elif args.command == "launch":
            _launch_dart_app(args.target, args.json)
        elif args.command == "surface":
            if args.target:
                _print(_save_surface(args.target), args.json)
            else:
                _run_surface_wizard(args.json)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1) from exc


if __name__ == "__main__":
    main()
