import importlib.util
import importlib._bootstrap_external as _bootstrap_ext
from pathlib import Path
import time

pyc = Path(__file__).parent / "__pycache__" / "sales_sim.cpython-313.pyc"
if not pyc.exists():
    raise SystemExit(f"pyc not found: {pyc}")

loader = _bootstrap_ext.SourcelessFileLoader('sales_sim', str(pyc))
spec = importlib.util.spec_from_loader(loader.name, loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)

print('Loaded sales_sim module')
for name in ['init_sales','simulate_sales','sales_thread','sales_history']:
    print(name, 'present:', hasattr(mod, name))

# Initialize if available
if hasattr(mod, 'init_sales'):
    try:
        mod.init_sales()
        print('init_sales() called')
    except Exception as e:
        print('init_sales() raised:', e)

# Start simulation: prefer starting thread if it's a Thread object, else start simulate_sales in a daemon thread
started = False
if hasattr(mod, 'sales_thread'):
    t = getattr(mod, 'sales_thread')
    try:
        # If it's a Thread object and not alive, start it
        import threading
        if hasattr(t, 'start') and not getattr(t, 'is_alive', lambda: False)():
            try:
                t.daemon = True
            except Exception:
                pass
            try:
                t.start()
                print('Started existing sales_thread')
                started = True
            except Exception as e:
                print('Could not start sales_thread:', e)
    except Exception as e:
        print('Error handling sales_thread:', e)

if not started and hasattr(mod, 'simulate_sales'):
    import threading
    try:
        thr = threading.Thread(target=mod.simulate_sales, daemon=True)
        thr.start()
        print('Started simulate_sales() in new thread')
        started = True
    except Exception as e:
        print('Could not start simulate_sales:', e)

if not started:
    print('No simulation started; exiting')
    raise SystemExit(0)

# Print sales_history periodically
for i in range(10):
    try:
        hist = getattr(mod, 'sales_history', None)
        print(f'[{i}] sales_history len:', len(hist) if hist is not None else 'None')
        if hist:
            print(' Latest:', hist[-5:])
    except Exception as e:
        print('Error reading sales_history:', e)
    time.sleep(1)

print('Runner finished')
