"""Convert pinned CC0 model downloads to ordinary Godot-compatible GLB files."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess

from setup_runtime import ROOT, download, get

WORK = ROOT / '.tools' / 'asset-review'
OUTPUT = ROOT / 'assets' / 'models'

def normalize_glb(target, renames=None):
    data = target.read_bytes()
    assert data[:4] == b'glTF' and struct.unpack_from('<I', data, 4)[0] == 2
    length = struct.unpack_from('<I', data, 12)[0]
    document = json.loads(data[20:20+length])
    assert not document.get('extensionsRequired'), 'An unsupported compression extension remains'
    names = {'steering_wheel': 'steering_column', **(renames or {})}
    # Godot interprets the _wheel suffix as a physics-node import hint.
    for node in document.get('nodes', []):
        node['name'] = names.get(node.get('name'), node.get('name', 'Part'))
    encoded = json.dumps(document, separators=(',', ':')).encode('utf-8')
    encoded += b' ' * (-len(encoded) % 4)
    tail = data[20+length:]
    data = struct.pack('<4sII', b'glTF', 2, 20+len(encoded)+len(tail)) + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded + tail
    target.write_bytes(data)
    return data

def run(arguments, env=None):
    result = subprocess.run([str(a) for a in arguments], capture_output=True, text=True,
                            env=env, creationflags=subprocess.CREATE_NO_WINDOW)
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)

def main():
    WORK.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    tools = [('ip7z/7zip', '26.06', ['7zr.exe', '7z2606-x64.exe']),
             ('KhronosGroup/KTX-Software', 'v4.4.2', ['KTX-Software-4.4.2-Windows-x64.exe'])]
    for repo, tag, filenames in tools:
        release = json.load(get(f'https://api.github.com/repos/{repo}/releases/tags/{tag}'))
        for filename in filenames:
            asset = next(a for a in release['assets'] if a['name'] == filename)
            download(asset['browser_download_url'], WORK / filename, asset['digest'].split(':')[1])
    if not (WORK / 'sevenzip' / '7z.exe').exists():
        run([WORK/'7zr.exe', 'x', WORK/'7z2606-x64.exe', '-o'+str(WORK/'sevenzip'), '-y'])
    if not (WORK / 'ktx' / 'bin' / 'ktx.exe').exists():
        run([WORK/'sevenzip/7z.exe', 'x', WORK/'KTX-Software-4.4.2-Windows-x64.exe', '-o'+str(WORK/'ktx'), '-y'])
    env = {**os.environ, 'PATH': str(WORK/'ktx/bin') + os.pathsep + os.environ['PATH']}
    npm = shutil.which('npm.cmd')
    if not npm:
        raise RuntimeError('Node.js/npm is required only to rebuild the model assets.')
    cli = [npm, 'exec', '--yes', '--prefix', str(WORK), '--package=@gltf-transform/cli@4.5.1', '--', 'gltf-transform']
    manifest_path = ROOT / 'assets/manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    for slug, lod, filename in [('family-sedan', 0, 'sedan_player.glb'),
                                ('family-sedan', 2, 'sedan_traffic.glb'),
                                ('strangler-fig', 1, 'street_tree.glb'),
                                ('non-step-city-bus', 0, 'city_bus.glb'),
                                ('casual-walker', 1, 'pedestrian_casual.glb'),
                                ('dog-walker', 1, 'pedestrian_older.glb'),
                                ('housing-facade-shop', 0, 'shopfront.glb'),
                                ('crate-of-apples', 1, 'produce_crate.glb'),
                                ('tied-burlap-sack', 1, 'burlap_sack.glb'),
                                ('soda-crate-pair', 1, 'drink_crates.glb')]:
        metadata = json.load(get(f'https://tevy.dev/models/{slug}.json'))
        assert metadata['license'] == 'CC0-1.0' and metadata['version'] == 1
        source = next(f for f in metadata['files'] if f['lod'] == lod)
        original = download('https://tevy.dev'+source['path'], WORK/f'{slug}-{lod}.glb', source['sha256'])
        decoded = WORK/f'{slug}-{lod}-decoded.glb'
        target = OUTPUT / filename
        run(cli+['ktxdecompress', original, decoded], env)
        run(cli+['dequantize', decoded, target], env)
        data = normalize_glb(target)
        relative = target.relative_to(ROOT).as_posix()
        manifest = [entry for entry in manifest if entry['file'] != relative]
        manifest.append({'file': relative, 'source': f'https://tevy.dev/models/{slug}',
                         'download': 'https://tevy.dev'+source['path'], 'license': 'CC0-1.0',
                         'source_sha256': source['sha256'], 'sha256': hashlib.sha256(data).hexdigest(),
                         'conversion': 'glTF Transform 4.5.1 ktxdecompress + dequantize; KTX-Software 4.4.2; steering_column node rename'})
        print(filename, len(data), 'bytes; verified CC0 source and decoded GLB', flush=True)
    source_url = 'https://grab3d.com/dl/tuk-tuk/tuk-tuk.glb'
    source_hash = '3e8e7c1851179acd8ac6ca2952fac992e24e426c509ec448dcf620ce8ab0469e'
    metadata = json.load(get('https://grab3d.com/dl/tuk-tuk/manifest.json'))
    assert metadata['extras']['license'] == 'CC0-1.0'
    original = download(source_url, WORK/'tuk-tuk-source.glb', source_hash)
    target = OUTPUT/'cng.glb'
    shutil.copyfile(original, target)
    data = normalize_glb(target, {'tuk-tuk_wheel_f': 'wheel_F', 'tuk-tuk_wheel_rl': 'wheel_RL',
                                  'tuk-tuk_wheel_rr': 'wheel_RR', 'tuk-tuk_handlebar': 'handlebar'})
    relative = target.relative_to(ROOT).as_posix()
    manifest = [entry for entry in manifest if entry['file'] != relative]
    manifest.append({'file': relative, 'source': 'https://grab3d.com/models/vehicles/tuk-tuk/',
                     'download': source_url, 'license': 'CC0-1.0', 'source_sha256': source_hash,
                     'sha256': hashlib.sha256(data).hexdigest(), 'conversion': 'Wheel/handlebar pivot names normalized; source geometry and textures retained'})
    # Both providers' downloads must remain reproducible and compression-free.
    assert len(data) > 900000 and metadata['triangles'] == 11899
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding='utf-8')

if __name__ == '__main__':
    main()
