from __future__ import annotations

import argparse
import getpass
import json
import os
import sys

from .api import VbpApi
from .session_store import SessionData, SessionStore


def _base_url() -> str:
    return os.environ.get("VBP_API_BASE_URL", "http://127.0.0.1:9090/api").rstrip("/")


def _session_store() -> SessionStore:
    home = os.environ.get("HOME", ".")
    return SessionStore(f"{home}/.vending-backpack/session.json")


def _print(obj: dict, as_json: bool) -> None:
    if as_json:
      print(json.dumps(obj, indent=2, sort_keys=True))
      return
    print(json.dumps(obj, indent=2, sort_keys=True))


def main() -> None:
    parser = argparse.ArgumentParser(prog="vbp")
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("health")
    sub.add_parser("login")
    sub.add_parser("logout")
    sub.add_parser("status")
    sub.add_parser("whoami")
    args = parser.parse_args()

    api = VbpApi(_base_url())
    store = _session_store()
    session = store.load()
    if session:
        api.set_access_token(session.access_token)

    try:
        if args.command == "health":
            _print(api.health(), args.json)
        elif args.command == "login":
            email = input("Email: ").strip()
            password = getpass.getpass("Password: ")
            org = input("Organization ID (optional): ").strip() or None
            response = api.login(email=email, password=password, organization_id=org)
            token = str(response.get("access_token", ""))
            if not token:
                raise RuntimeError("Missing access token")
            api.set_access_token(token)
            store.save(SessionData(access_token=token, user=dict(response.get("user", {}))))
            _print(response, args.json)
        elif args.command in {"status", "whoami"}:
            if not session:
                print("Not signed in.")
                return
            _print(api.me(), args.json)
        elif args.command == "logout":
            store.clear()
            print("Session cleared.")
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1) from exc


if __name__ == "__main__":
    main()

