"""Run tests through the existing Windows Stata MCP legacy SSE endpoint.
The package must already be accessible under --working-dir on Windows.
Requires requests. Uses a dedicated Stata session; tests clear that session's data.
"""
import argparse
import json
import queue
import threading
import uuid
from urllib.parse import urljoin
import requests

p = argparse.ArgumentParser()
p.add_argument('--url', default='http://localhost:4000/mcp')
p.add_argument('--working-dir', required=True, help='Windows directory containing preleveldose.ado')
p.add_argument('--session-id', default='pld-test-'+uuid.uuid4().hex[:10])
p.add_argument('--timeout', type=int, default=120)
a = p.parse_args()
messages = queue.Queue()

def read_events():
    try:
        with requests.get(a.url, stream=True, timeout=(10, a.timeout+30)) as r:
            r.raise_for_status()
            event, data = None, []
            for line in r.iter_lines(chunk_size=1, decode_unicode=True):
                if not line:
                    if data:
                        messages.put((event, '\n'.join(data)))
                        event, data = None, []
                elif line.startswith('event:'):
                    event = line[6:].strip()
                elif line.startswith('data:'):
                    data.append(line[5:].strip())
    except Exception as e:
        messages.put(('error', str(e)))

threading.Thread(target=read_events, daemon=True).start()
event, endpoint = messages.get(timeout=15)
if event != 'endpoint':
    raise SystemExit(f'MCP endpoint discovery failed: {event}: {endpoint}')
endpoint = urljoin(a.url, endpoint)

def call(method, params, request_id=None):
    body = dict(jsonrpc='2.0', method=method, params=params)
    if request_id is not None:
        body['id'] = request_id
    requests.post(endpoint, json=body, timeout=15).raise_for_status()
    if request_id is None:
        return
    while True:
        event, data = messages.get(timeout=a.timeout+30)
        if event == 'error':
            raise SystemExit(data)
        obj = json.loads(data)
        if obj.get('id') == request_id:
            if 'error' in obj:
                raise SystemExit(json.dumps(obj['error']))
            return obj['result']

call('initialize', dict(protocolVersion='2024-11-05', capabilities={},
     clientInfo=dict(name='pld-ado-validation', version='0.6')), 1)
call('notifications/initialized', {})
selection = '''capture log close pldvalidation
log using "tests/stata18-validation.log", name(pldvalidation) text replace
display "VALIDATION_ENVIRONMENT: Stata " c(stata_version)
do tests/run.do
log close pldvalidation'''
result = call('tools/call', dict(name='stata_run_selection', arguments=dict(
    selection=selection, session_id=a.session_id, working_dir=a.working_dir,
    timeout=a.timeout)), 2)
output = '\n'.join(x['text'] for x in result.get('content', []) if x.get('type') == 'text')
print(output)
if result.get('isError') or '\nPASS: preleveldose Stata regression checks' not in output:
    raise SystemExit('FAILED: a fresh Stata success marker was not received.')
print('Validated through MCP session '+a.session_id)
