from __future__ import annotations

import json
import os
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
        flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
        fd = os.open(self.path, flags, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(
                json.dumps(
                    {"access_token": session.access_token, "user": session.user},
                    indent=2,
                    sort_keys=True,
                )
            )
        os.chmod(self.path, 0o600)

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
