"""Verify the packaged Windows executable without using the editor project."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build' / 'v2.0'

def scenario(flag, marker):
    log = ROOT / 'artifacts' / f'exported-{flag}.log'
    process = subprocess.run([str(BUILD / 'DhakaDeadline.exe'), '--headless', '--fixed-fps', '60',
                              '--log-file', str(log), '--', '--' + flag],
                             cwd=BUILD, timeout=90, creationflags=subprocess.CREATE_NO_WINDOW,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = log.read_text(encoding='utf-8')
    if process.returncode or 'ERROR:' in output or 'WARNING:' in output:
        raise RuntimeError(f'{flag}: exit {process.returncode}\n{output[-4000:]}')
    result = json.loads(next(line.split(marker, 1)[1] for line in output.splitlines() if marker in line))
    return flag, result

def main():
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(scenario, 'autodrive', 'AUTODRIVE_ARRIVED '),
                   pool.submit(scenario, 'smoke', 'SMOKE_REPORT ')]
        results = dict(f.result() for f in futures)
    archive = BUILD / 'DhakaDeadline-Windows.zip'
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise RuntimeError('ZIP CRC verification failed')
        required = {'DhakaDeadline.exe', 'DhakaDeadline.pck', 'Godot-LICENSE.txt', 'Godot-COPYRIGHT.txt',
                    'OFL.txt', 'THIRD_PARTY_NOTICES.md', 'README.md', 'asset-manifest.json'}
        if set(package.namelist()) != required:
            raise RuntimeError(f'Unexpected package contents: {package.namelist()}')
        for name in required:
            if hashlib.sha256(package.read(name)).digest() != hashlib.sha256((BUILD/name).read_bytes()).digest():
                raise RuntimeError('Package mismatch: ' + name)
    results['package'] = {'file': archive.name, 'bytes': archive.stat().st_size,
                          'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'members': sorted(required)}
    (ROOT / 'artifacts/export-verification.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print('Exported driving, traffic, ZIP integrity and file parity: PASS')
    print(json.dumps({k: v for k, v in results['smoke'].items() if k != 'agent_states'}, indent=2))
    print(json.dumps(results['autodrive'], indent=2))

if __name__ == '__main__':
    main()
