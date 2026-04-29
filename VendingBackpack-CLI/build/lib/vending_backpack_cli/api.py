from __future__ import annotations

import requests


class VbpApi:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.access_token: str | None = None

    def set_access_token(self, token: str | None) -> None:
        self.access_token = token

    def health(self) -> dict:
        response = requests.get(self.base_url.replace("/api", "") + "/health", timeout=10)
        response.raise_for_status()
        return response.json()

    def login(self, email: str, password: str, organization_id: str | None = None) -> dict:
        payload = {"email": email, "password": password}
        if organization_id:
            payload["organization_id"] = organization_id
        return self._post("/token", payload)

    def me(self) -> dict:
        return self._get("/me")

    def _get(self, path: str) -> dict:
        response = requests.get(
            self.base_url + path,
            headers=self._headers(),
            timeout=10,
        )
        return self._parse(response)

    def _post(self, path: str, payload: dict) -> dict:
        response = requests.post(
            self.base_url + path,
            json=payload,
            headers=self._headers(json_body=True),
            timeout=10,
        )
        return self._parse(response)

    def _headers(self, json_body: bool = False) -> dict:
        headers: dict[str, str] = {}
        if json_body:
            headers["Content-Type"] = "application/json"
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        return headers

    @staticmethod
    def _parse(response: requests.Response) -> dict:
        if response.ok:
            return response.json()
        detail = ""
        try:
            payload = response.json()
            if isinstance(payload, dict):
                detail = str(payload.get("detail") or payload.get("error") or "")
        except ValueError:
            detail = response.text.strip()
        raise RuntimeError(detail or f"Request failed with status {response.status_code}")

