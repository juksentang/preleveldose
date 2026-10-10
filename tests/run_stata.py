"""Run the supplied Stata batch checks when a licensed executable is available."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--stata',help='Path to a licensed Stata executable')
a=p.parse_args()
binary=a.stata or next((shutil.which(x) for x in ('stata-mp','stata-se','stata') if shutil.which(x)),None)
if not binary:
    sys.exit('NOT RUN: no Stata executable found; supply --stata /path/to/stata. No runtime validation claimed.')
if (root.parent/'toolkit/prelevel_dose.py').exists():
    subprocess.run([sys.executable,str(root/'tests/make_reference.py')],check=True)
# A standalone source archive includes the already generated reference assertions.
log=root/'run.log'
if log.exists():
    log.unlink()  # prevent a stale success marker from passing a failed run
result=subprocess.run([binary,'-b','do','tests/run.do'],cwd=root)
text=log.read_text(errors='replace') if log.exists() else ''
if result.returncode or 'PASS: preleveldose Stata regression checks' not in text:
    sys.exit(f'FAILED: inspect {log}; process exit {result.returncode}')
print(f'PASS: Stata batch checks; log {log}')
