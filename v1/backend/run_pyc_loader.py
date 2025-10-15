import importlib._bootstrap_external as _bootstrap_ext
import importlib.util
from pathlib import Path

pyc = Path(__file__).parent / "__pycache__" / "sales_sim.cpython-313.pyc"
if not pyc.exists():
    raise SystemExit(f"pyc not found: {pyc}")

loader = _bootstrap_ext.SourcelessFileLoader('sales_sim', str(pyc))
spec = importlib.util.spec_from_loader(loader.name, loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)

print('Loaded module:', mod.__name__)
attrs = [a for a in dir(mod) if not a.startswith('_')]
print('Public attributes:', attrs)

if 'app' in attrs:
    print('Found attribute `app` ->', getattr(mod, 'app'))
if 'create_app' in attrs:
    print('Found factory `create_app`')
if 'main' in attrs:
    print('Found main')

# If the module defines a Flask app, try to show its routes
try:
    app = getattr(mod, 'app', None)
    if app is not None:
        try:
            rules = list(app.url_map.iter_rules())
            print('Routes:')
            for r in rules:
                print(' ', r)
        except Exception as e:
            print('Could not list routes:', e)
except Exception as e:
    print('Error inspecting app:', e)
