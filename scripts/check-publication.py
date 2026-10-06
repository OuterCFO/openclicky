#!/usr/bin/env python3
"""Check the Git snapshot for common private files and credential patterns."""
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
paths = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z'], text=True).split('\0')
patterns = [
    re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    re.compile(rb'sk-(?:proj-|ant-api\d{2}-)?[A-Za-z0-9_-]{45,}'),
    re.compile(rb'gh[pousr]_[A-Za-z0-9]{30,}'),
]
forbidden = {'auth.json', 'secrets.env', 'Local.xcconfig', '.env', '.env.local'}
failures = []
for name in filter(None, paths):
    path = root / name
    if not path.is_file():
        continue
    if path.name in forbidden or name.startswith('AppResources/OpenClicky/CodexRuntime/'):
        failures.append(f'Private/generated file tracked: {name}')
    data = path.read_bytes()
    if any(pattern.search(data) for pattern in patterns):
        failures.append(f'Credential-like value found: {name}')
    if (str(Path.home()) + '/').encode() in data or (name.endswith('project.pbxproj') and re.search(rb'DEVELOPMENT_TEAM = [A-Z0-9]{10};', data)):
        failures.append(f'Personal development path/team found: {name}')
if failures:
    print('\n'.join(failures), file=sys.stderr)
    sys.exit(1)
print(f'Publication hygiene passed for {len(list(filter(None, paths)))} tracked paths.')
print('This is a heuristic check, not a comprehensive security audit.')
