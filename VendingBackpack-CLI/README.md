# VendingBackpack CLI

Python terminal client for the VendingBackpack Rails API.

## Run

```bash
cd VendingBackpack-CLI
python3 -m pip install -e .
vbp
```

## Config

- `VBP_API_BASE_URL`: defaults to `http://127.0.0.1:9090/api`
- Session file: `~/.vending-backpack/session.json`

## Commands

- `wizard` or plain `vbp`
- `health`
- `login`
- `logout`
- `status`
- `whoami`
- `surface`
- `launch`

## Wizard Flow

`vbp` opens a numbered wizard:

1. Login
2. Who am I
3. Backend health
4. Surface control for Dart app
5. Launch Dart app
6. Logout
7. Exit

`surface` writes a small control file to `~/.vending-backpack/surface-control.json`.
The Flutter app reads that file on startup and opens the requested surface first when possible.
`launch` opens the built macOS Flutter app and can set the startup surface first.
