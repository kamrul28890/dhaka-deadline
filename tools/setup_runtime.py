"""Fetch pinned official Godot binaries and CC0 references, without installation."""
from pathlib import Path
import hashlib
import io
import json
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '4.7.2-stable'
BASE = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}/'
HEADERS = {'User-Agent': 'DhakaDeadline/0.1 (local game prototype)'}

def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=90)

def download(url, path, digest=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        print('Downloading', path.name, flush=True)
        with get(url) as source, path.with_suffix(path.suffix + '.part').open('wb') as target:
            while chunk := source.read(1024 * 1024):
                target.write(chunk)
        path.with_suffix(path.suffix + '.part').replace(path)
    if digest and hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        raise RuntimeError(f'SHA256 mismatch: {path}')
    return path

class RemoteZip(io.RawIOBase):
    """Read only selected members of the official 1.2 GB template archive."""
    def __init__(self, url):
        with get(url) as response:
            self.url = response.url
            self.size = int(response.headers['Content-Length'])
        self.pos = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.pos
    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.size + offset
        return self.pos
    def read(self, n=-1):
        n = min(n if n >= 0 else self.size - self.pos, self.size - self.pos)
        if n <= 0: return b''
        request = urllib.request.Request(self.url, headers={**HEADERS, 'Range': f'bytes={self.pos}-{self.pos+n-1}'})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError('Server does not support selective template downloads')
            data = response.read(n)
        self.pos += len(data)
        return data

def main():
    runtime = ROOT / '.tools' / 'godot'
    sums = get(BASE + 'SHA512-SUMS.txt').read().decode()
    filename = f'Godot_v{VERSION}_win64.exe.zip'
    expected = next(line.split()[0] for line in sums.splitlines() if line.split()[-1].lstrip('*') == filename)
    archive = download(BASE + filename, runtime / filename)
    if hashlib.sha512(archive.read_bytes()).hexdigest() != expected:
        raise RuntimeError('Official Godot checksum mismatch')
    with zipfile.ZipFile(archive) as z:
        z.extractall(runtime)
    print('Official Godot binary verified.', flush=True)
    assets = []
    for asset, maps in [('asphalt_02', [('diff', 'jpg'), ('nor_gl', 'jpg'), ('rough', 'jpg')]),
                        ('painted_plaster_wall', [('diff', 'jpg'), ('nor_gl', 'jpg'), ('rough', 'jpg')]),
                        ('kloppenheim_06_puresky', [('hdri', 'hdr')])]:
        data = json.load(get('https://api.polyhaven.com/files/' + asset))
        for channel, extension in maps:
            key = {'diff': 'Diffuse', 'rough': 'Rough'}.get(channel, channel)
            entry = data[key]['2k' if channel == 'hdri' else '1k'][extension]
            name = f'{asset}_{channel}.{extension}'
            path = download(entry['url'], ROOT / 'assets' / 'textures' / name)
            if hashlib.md5(path.read_bytes()).hexdigest() != entry['md5']:
                raise RuntimeError('Asset checksum mismatch: ' + name)
            assets.append({'file': 'assets/textures/' + name, 'source': 'https://polyhaven.com/a/' + asset,
                           'download': entry['url'], 'license': 'CC0-1.0', 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    # Google Fonts distributes the same OFL font with a stable repository layout.
    font_url = 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosansbengali/NotoSansBengali%5Bwdth,wght%5D.ttf'
    font = download(font_url, ROOT / 'assets/fonts/NotoSansBengali.ttf')
    download('https://raw.githubusercontent.com/google/fonts/main/ofl/notosansbengali/OFL.txt', ROOT / 'assets/fonts/OFL.txt')
    assets.append({'file': 'assets/fonts/NotoSansBengali.ttf', 'source': 'https://github.com/google/fonts/tree/main/ofl/notosansbengali', 'license': 'OFL-1.1', 'sha256': hashlib.sha256(font.read_bytes()).hexdigest()})
    manifest_path = ROOT / 'assets/manifest.json'
    previous = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else []
    refreshed = {entry['file'] for entry in assets}
    assets += [entry for entry in previous if entry['file'] not in refreshed]
    assert {entry['file'] for entry in previous} <= {entry['file'] for entry in assets}, 'Existing asset provenance must be preserved'
    manifest_path.write_text(json.dumps(assets, indent=2), encoding='utf-8')
    for name in ['LICENSE.txt', 'COPYRIGHT.txt']:
        download(f'https://raw.githubusercontent.com/godotengine/godot/{VERSION}/' + name,
                 ROOT / 'assets/licenses' / ('Godot-' + name))
    print('CC0 textures, sky and OFL Bengali font verified.', flush=True)
    template = runtime / 'windows_release_x86_64.exe'
    if not template.exists():
        print('Fetching only the Windows release export template...', flush=True)
        with zipfile.ZipFile(RemoteZip(BASE + f'Godot_v{VERSION}_export_templates.tpz')) as z:
            member = next(n for n in z.namelist() if n.endswith('/windows_release_x86_64.exe'))
            template.write_bytes(z.read(member))  # ZipFile verifies the archive member CRC.
    print('Setup complete:', runtime, flush=True)

if __name__ == '__main__':
    main()
