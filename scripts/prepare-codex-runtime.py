#!/usr/bin/env python3
"""Prepare pinned official Codex binaries without copying anyone's login or config."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / 'scripts/codex-runtime-manifest.json').read_text())

def prepare(architecture, destination, archive=None):
    spec = MANIFEST['architectures'][architecture]
    triple = spec['triple']
    with tempfile.TemporaryDirectory(prefix='openclicky-codex-') as temporary:
        temporary = Path(temporary)
        package = Path(archive) if archive else temporary / 'codex.tgz'
        if not archive:
            print(f"Downloading official Codex {MANIFEST['version']} ({architecture})...", flush=True)
            with urllib.request.urlopen(spec['url'], timeout=120) as response, package.open('wb') as output:
                shutil.copyfileobj(response, output)
        digest = hashlib.sha512()
        with package.open('rb') as source:
            for block in iter(lambda: source.read(1024 * 1024), b''):
                digest.update(block)
        expected = base64.b64decode(spec['integrity'].removeprefix('sha512-'))
        if digest.digest() != expected:
            raise ValueError('Codex archive integrity mismatch; no runtime was installed')
        staged = temporary / 'runtime'
        binaries = staged / 'vendor' / triple / 'bin'
        binaries.mkdir(parents=True)
        with tarfile.open(package, 'r:gz') as tar:
            # Extract only named regular files, never archive paths or symlinks.
            for name in ('codex', 'codex-code-mode-host'):
                member = tar.getmember(f'package/vendor/{triple}/bin/{name}')
                if not member.isfile():
                    raise ValueError(f'{name} is not a regular file')
                with tar.extractfile(member) as source, (binaries / name).open('wb') as output:
                    shutil.copyfileobj(source, output)
                (binaries / name).chmod(0o755)
        (staged / 'bin').mkdir()
        wrapper = staged / 'bin/codex'
        wrapper.write_text('#!/bin/sh\nRUNTIME_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"\nexec "$RUNTIME_ROOT/vendor/' + triple + '/bin/codex" "$@"\n')
        wrapper.chmod(0o755)
        shutil.copy2(ROOT / 'THIRD_PARTY_LICENSES/Codex-APACHE-2.0.txt', staged / 'LICENSE')
        (staged / 'manifest.json').write_text(json.dumps({'version': MANIFEST['version'], 'architecture': architecture, 'integrity': spec['integrity']}, indent=2) + '\n')
        destination = Path(destination)
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copytree(staged, destination, dirs_exist_ok=True)
    if architecture == platform.machine():
        result = subprocess.check_output([str(destination / 'bin/codex'), '--version'], text=True).strip()
        if result != 'codex-cli ' + MANIFEST['version']:
            raise ValueError(f'Unexpected runtime version: {result}')
        print(result)
    print(f'Runtime ready at {destination}. Authentication is separate; no credentials were read.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--architecture', choices=MANIFEST['architectures'], default=platform.machine())
    parser.add_argument('--destination', type=Path, default=ROOT / 'AppResources/OpenClicky/CodexRuntime')
    parser.add_argument('--archive', type=Path, help='Use a previously downloaded archive; integrity is still checked')
    args = parser.parse_args()
    if platform.system() != 'Darwin':
        parser.error('This runtime preparation command supports macOS only')
    prepare(args.architecture, args.destination, args.archive)
