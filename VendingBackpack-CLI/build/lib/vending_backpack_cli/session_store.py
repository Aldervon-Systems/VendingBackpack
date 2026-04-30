from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path


@dataclass
class SessionData:
    access_token: str
    user: dict


class SessionStore:
    def __init__(self, path: str) -> None:
        self.path = Path(path)

    def save(self, session: SessionData) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(
            json.dumps(
                {"access_token": session.access_token, "user": session.user},
                indent=2,
                sort_keys=True,
            ),
            encoding="utf-8",
        )

    def load(self) -> SessionData | None:
        if not self.path.exists():
            return None
        payload = json.loads(self.path.read_text(encoding="utf-8"))
        return SessionData(
            access_token=str(payload.get("access_token", "")),
            user=dict(payload.get("user", {})),
        )

    def clear(self) -> None:
        if self.path.exists():
            self.path.unlink()

